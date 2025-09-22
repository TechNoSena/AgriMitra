import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'homepage.dart';
import 'farm_data_provider.dart';
import 'secrets.dart'; // Gemini API Key ke liye

class ControlPanelPage extends ConsumerStatefulWidget {
  final BluetoothDevice? device;
  final String areaName;

  const ControlPanelPage({super.key, this.device, required this.areaName});

  @override
  ConsumerState<ControlPanelPage> createState() => _ControlPanelPageState();
}

class _ControlPanelPageState extends ConsumerState<ControlPanelPage> {
  // State Variables
  bool _isSensorDeployed = false;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  StreamSubscription<List<int>>? _readSubscription;
  late StreamSubscription<BluetoothConnectionState>
  _connectionStateSubscription;
  bool _isReady = false;
  bool _isConnected = false;
  String _ambientTemperature = "--°C";
  String _soilTemperature = "--°C";
  String _humidity = "--%";

  // Standard UUIDs for BLE UART service
  final Guid UART_SERVICE_UUID = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid UART_TX_CHAR_UUID = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
  final Guid UART_RX_CHAR_UUID = Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

  @override
  void initState() {
    super.initState();
    _loadLastData();

    if (widget.device != null) {
      _connectionStateSubscription = widget.device!.connectionState.listen((
        state,
      ) {
        if (mounted) {
          final isCurrentlyConnected =
              (state == BluetoothConnectionState.connected);
          if (_isConnected != isCurrentlyConnected) {
            setState(() {
              _isConnected = isCurrentlyConnected;
              if (!_isConnected) {
                _isReady = false; // Reset ready state on disconnect
              }
            });
          }
          if (_isConnected && !_isReady) {
            _discoverServicesAndListen();
          }
        }
      });
      // Initial check
      if (widget.device!.isConnected) {
        _isConnected = true;
        _discoverServicesAndListen();
      }
    }
  }

  @override
  void dispose() {
    _readSubscription?.cancel();
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadLastData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedJson = prefs.getString("${widget.areaName}_data");

    if (savedJson != null) {
      final Map<String, dynamic> data = json.decode(savedJson);
      if (mounted) {
        setState(() {
          _updateSensorUI(data);
        });
      }
    }
  }

  Future<void> _saveData(Map<String, dynamic> cleanData) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonToSave = json.encode(cleanData);
    await prefs.setString("${widget.areaName}_data", jsonToSave);
    print("💾 Saved new data for ${widget.areaName}: $jsonToSave");
  }

  void _discoverServicesAndListen() async {
    if (!_isConnected || widget.device == null) return;

    setState(() {
      _isReady = false;
    });

    List<BluetoothService> services = await widget.device!.discoverServices();
    for (var service in services) {
      if (service.uuid == UART_SERVICE_UUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == UART_TX_CHAR_UUID) {
            _writeCharacteristic = characteristic;
          }
          if (characteristic.uuid == UART_RX_CHAR_UUID) {
            _readCharacteristic = characteristic;
          }
        }
      }
    }

    if (_writeCharacteristic != null && _readCharacteristic != null) {
      print("✅ UART Service and Characteristics Found!");
      await _readCharacteristic!.setNotifyValue(true);
      _readSubscription = _readCharacteristic!.onValueReceived.listen((value) {
        _handleIncomingData(value);
      });
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    } else {
      print("❌ UART Service or Characteristics Not Found!");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Required Rover service not found."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleIncomingData(List<int> value) {
    if (value.isEmpty) return;
    try {
      final String rawJsonString = utf8.decode(value);
      final Map<String, dynamic> rawData = json.decode(rawJsonString);
      print("➡️ Received RAW JSON from ESP32: $rawJsonString");

      final double temp1 =
          double.tryParse(
            rawData['temp1'].toString().replaceAll('°C', '').trim(),
          ) ??
          0.0;
      final double temp2_raw =
          double.tryParse(rawData['temp2'].toString().trim()) ?? 0.0;
      final double hum =
          double.tryParse(
            rawData['humidity'].toString().replaceAll('%', '').trim(),
          ) ??
          0.0;

      final cleanData = {'temp1': temp1, 'temp2': temp2_raw, 'hum': hum};

      if (mounted) {
        setState(() {
          _updateSensorUI(cleanData);
        });
      }

      _getPredictionFromServer(cleanData);
      _saveData(cleanData);
    } catch (e) {
      print("⚠️ Error parsing incoming data: $e");
    }
  }

  void _updateSensorUI(Map<String, dynamic> data) {
    num temp1Value = data['temp1'] ?? 0;
    num humValue = data['hum'] ?? 0;

    num calculatedSoilTemp = temp1Value - 15;

    _ambientTemperature = "${temp1Value.toStringAsFixed(1)}°C";
    _soilTemperature = "${calculatedSoilTemp.toStringAsFixed(1)}°C";
    _humidity = "${humValue.toStringAsFixed(1)}%";
  }

  Future<void> _getPredictionFromServer(
    Map<String, dynamic> cleanEspData,
  ) async {
    final url = "http://82.23.170.173:8000/predict";
    final predictionNotifier = ref.read(predictionProvider.notifier);
    predictionNotifier.state = "Getting prediction...";

    num soilTempForServer = (cleanEspData['temp1'] ?? 0);

    final serverData = {
      "temperature": soilTempForServer,
      "humidity": cleanEspData['hum'],
      "ph": 7.0,
      "rainfall": 100.0,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(serverData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> predictionData = json.decode(response.body);
        print("✅ Got prediction: $predictionData");

        final String cropLabel =
            predictionData['predicted_crop_label'] ?? "Unknown";
        final double confidence = predictionData['confidence'] ?? 0.0;
        final int confidencePercent = (confidence * 100).round();

        predictionNotifier.state =
            "${cropLabel.toUpperCase()} ($confidencePercent%)";

        _getGeminiRecommendations(cleanEspData, predictionData);
      } else {
        print("❌ Server Error: ${response.statusCode} - ${response.body}");
        predictionNotifier.state = "Server Error";
      }
    } catch (e) {
      print("❌ Network Error: $e");
      predictionNotifier.state = "Network Error";
    }
  }

  Future<void> _getGeminiRecommendations(
    Map<String, dynamic> soilData,
    Map<String, dynamic> predictionData,
  ) async {
    final geminiNotifier = ref.read(geminiRecommendationProvider.notifier);
    geminiNotifier.state = null;

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: geminiApiKey,
    );

    num soilTempForGemini = (soilData['temp1'] ?? 0);

    final prompt =
        """
    Analyze the following Indian farm data. You MUST respond ONLY with a valid JSON object. Do not add any text or markdown formatting before or after the JSON.
    You are a LLM based on recommending and helping the farmers. only give results that are positive, try to find everything positive and concise
    One line answers for each key.
    DATA:
    - Atomosphere Temperature: $soilTempForGemini°C
    - Atomsphere Humidity: ${soilData['hum']}%
    - Predicted Crop: ${predictionData['predicted_crop_label']}
    - Prediction Confidence: ${(predictionData['confidence'] * 100).toStringAsFixed(1)}%

    The required JSON output structure is:
    {" recommended_breeding/mutation" : "recommend the mutation or breeding required to tackle the below trait and problems .Note give the real life plant or some data dont write the problem multiple times"
      "recommended_trait": "The single most beneficial genetic trait for the crop in these conditions .",
      "reason": "A brief, simple explanation for the farmer on why this trait is important based on the provided data.",
      "suggested_action": "A simple, actionable step for the farmer, e.g., 'Cross-breed with local heat-tolerant variants' or 'Select seeds certified for high humidity tolerance'."
    }
    """;

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final rawResponse = response.text ?? "";
      print("✅ Got Gemini Response: $rawResponse");

      final cleanJsonString = rawResponse
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();
      final geminiJson = json.decode(cleanJsonString);
      final recommendation = BreedingRecommendation.fromJson(geminiJson);

      geminiNotifier.state = recommendation;
    } catch (e) {
      print("❌ Gemini API Error or JSON Parsing Error: $e");
      geminiNotifier.state = BreedingRecommendation(
        recommendedbreedingmutation: "meow",
        recommendedTrait: "Error",
        reason: "Could not generate advice from AI.",
        suggestedAction: "Please try again later.",
      );
    }
  }

  void _sendData(String data) {
    if (!_isConnected || _writeCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rover is not connected."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    List<int> bytes = utf8.encode(data);
    _writeCharacteristic!.write(bytes, withoutResponse: false);
    print("📡 Sent via BLE: $data");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.areaName,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          const Icon(
            Icons.notifications_none_outlined,
            color: Colors.black54,
            size: 30,
          ),
          const SizedBox(width: 12),
          const CircleAvatar(radius: 20, backgroundColor: Color(0xFFE0E0E0)),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: Colors.white,
      body: (_isReady && _isConnected) ? buildControlUI() : buildLoadingUI(),
    );
  }

  Widget buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            _isConnected
                ? "Preparing Rover Controls..."
                : "Rover disconnected. Please reconnect.",
            style: GoogleFonts.poppins(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget buildControlUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSoilHealthCard(context),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    text: 'Get Start Location',
                    icon: Icons.gps_fixed,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    text: 'Get End Location',
                    icon: Icons.gps_not_fixed,
                    onPressed: () {},
                  ),
                ],
              ),
              _buildRemoteControl(),
            ],
          ),
          const Spacer(),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_isSensorDeployed) {
                  _sendData("D");
                } else {
                  _sendData("A");
                }
                setState(() {
                  _isSensorDeployed = !_isSensorDeployed;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSensorDeployed
                    ? Colors.redAccent
                    : const Color(0xFF2C3E50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: Text(
                _isSensorDeployed ? 'Undeploy Sensor' : 'Deploy Sensor',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRemoteControl() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRemoteButton(icon: Icons.arrow_upward, command: "F"),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRemoteButton(icon: Icons.arrow_back, command: "L"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  onPressed: () => _sendData("S"),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(15),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.stop),
                ),
              ),
              _buildRemoteButton(icon: Icons.arrow_forward, command: "R"),
            ],
          ),
          _buildRemoteButton(icon: Icons.arrow_downward, command: "B"),
        ],
      ),
    );
  }

  Widget _buildRemoteButton({required IconData icon, required String command}) {
    return IconButton(
      icon: Icon(icon, color: Colors.blue.shade800),
      iconSize: 32,
      onPressed: () => _sendData(command),
    );
  }

  Widget _buildSoilHealthCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soil Health',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A4750),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: () {
                  _sendData("T");
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTappableInfoCard(
                  context,
                  _ambientTemperature,
                  'Ambient Temp',
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTappableInfoCard(
                  context,
                  _humidity,
                  'Humidity',
                  () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTappableInfoCard(
                  context,
                  _soilTemperature,
                  'Soil Temp',
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrient Info:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A4750),
                        ),
                      ),
                      Text(
                        'N : 120 mg/kg',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      Text(
                        'P : 45 mg/kg',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      Text(
                        'K : 80 mg/kg',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE3F2FD),
        foregroundColor: Colors.blue.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.2),
      ),
    );
  }

  Widget _buildTappableInfoCard(
    BuildContext context,
    String value,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A4750),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3A4750),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
