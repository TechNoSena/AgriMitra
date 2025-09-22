import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'control_panel_page.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Model for our farm area data
class FarmArea {
  final String name;
  final double acres;
  final IconData icon;

  const FarmArea({required this.name, required this.acres, required this.icon});
}

class RoverPage extends StatefulWidget {
  final List<FarmArea> farmAreas;
  final Function(String, double) onAddArea;

  const RoverPage({
    super.key,
    required this.farmAreas,
    required this.onAddArea,
  });

  @override
  State<RoverPage> createState() => _RoverPageState();
}

class _RoverPageState extends State<RoverPage> {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool isConnecting = false;
  bool _isConnected = false;

  // Aapka ESP32-C5 ka MAC address
  final String esp32MacAddress =
      "D0:CF:13:E0:A2:02"; // IMPORTANT: Use your real MAC address

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  Future<void> _connectToESP32() async {
    if (isConnecting) return;
    setState(() => isConnecting = true);

    Timer? scanTimeout;

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.remoteId.toString().toUpperCase() ==
            esp32MacAddress.toUpperCase()) {
          print("✅ Device Found! Attempting to connect...");
          scanTimeout?.cancel();
          FlutterBluePlus.stopScan();
          _scanSubscription?.cancel();

          _performConnection(r.device);
          break;
        }
      }
    });

    scanTimeout = Timer(const Duration(seconds: 15), () {
      print("⚠️ Scan Timeout: Device not found.");
      if (mounted) {
        FlutterBluePlus.stopScan();
        _scanSubscription?.cancel();
        setState(() => isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rover not found. Make sure it's ON."),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> _performConnection(BluetoothDevice device) async {
    try {
      await device.connect();
      if (!mounted) return;
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        isConnecting = false;
      });
      print("✅ Connected to ESP32!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rover Connected!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("⚠️ Cannot connect: $e");
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to connect."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rover',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              isConnecting
                  ? "Connecting..."
                  : (_isConnected ? "Connected" : "Disconnected"),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade600),
            onPressed: _isConnected ? null : _connectToESP32,
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(
              'assets/images/pfp.png',
            ), // Yahan image add ki
            backgroundColor: Color(
              0xFFE0E0E0,
            ), // Fallback color agar image load na ho
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'ROVER STATUS',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _isConnected
                          ? _buildBatteryIndicator()
                          : _buildConnectButton(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Farm Areas',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: widget.farmAreas.length,
                itemBuilder: (context, index) {
                  return _buildAreaGridItem(context, widget.farmAreas[index]);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAreaForm(context),
        label: Text(
          'Add Area',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: 200,
      height: 200,
      child: ElevatedButton(
        onPressed: isConnecting ? null : _connectToESP32,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: const Color(0xFFE3F2FD),
          foregroundColor: Colors.blue.shade800,
          elevation: 5,
        ),
        child: Text(
          isConnecting ? 'Connecting...' : 'Connect',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    return CircularPercentIndicator(
      radius: 100.0,
      lineWidth: 20.0,
      percent: 0.80,
      center: Text(
        "80%",
        style: GoogleFonts.poppins(
          color: const Color(0xFF3A4750),
          fontWeight: FontWeight.bold,
          fontSize: 40,
        ),
      ),
      progressColor: const Color(0xFFC5CAE9),
      backgroundColor: Colors.grey.shade200,
      circularStrokeCap: CircularStrokeCap.round,
    );
  }

  Widget _buildAreaGridItem(BuildContext context, FarmArea area) {
    return GestureDetector(
      onTap: () {
        if (_connectedDevice != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ControlPanelPage(
                device: _connectedDevice!,
                areaName: area.name,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please connect to the Rover first."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F8FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(area.icon, size: 40, color: Colors.blue.shade700),
            const SizedBox(height: 12),
            Text(
              area.name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${area.acres} acres',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAreaForm(BuildContext context) {
    final nameController = TextEditingController();
    final acresController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Farm Area',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Area Name (e.g., North Field)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: acresController,
                decoration: InputDecoration(
                  labelText: 'Size (in acres)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text;
                    final acres = double.tryParse(acresController.text) ?? 0.0;
                    if (name.isNotEmpty && acres > 0) {
                      widget.onAddArea(name, acres);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Area'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
