import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For formatting the time

// --- 1. Model Class for the API Data ---
class MarketRecord {
  final String commodity;
  final String market;
  final String modalPrice;
  final String minPrice;

  MarketRecord({
    required this.commodity,
    required this.market,
    required this.modalPrice,
    required this.minPrice,
  });

  // Factory constructor to parse JSON
  factory MarketRecord.fromJson(Map<String, dynamic> json) {
    return MarketRecord(
      commodity: json['commodity'] ?? 'Unknown',
      market: json['market'] ?? 'N/A',
      modalPrice: json['modal_price'] ?? '0',
      minPrice: json['min_price'] ?? '0',
    );
  }
}

// --- 2. The Main Page Widget ---
class MarketPricesPage extends StatefulWidget {
  const MarketPricesPage({super.key});

  @override
  State<MarketPricesPage> createState() => _MarketPricesPageState();
}

class _MarketPricesPageState extends State<MarketPricesPage> {
  bool _isLoading = true;
  String _errorMessage = "";
  List<MarketRecord> _records = [];
  String _lastCheckedTime = "";

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
  }

  Future<void> _fetchMarketData() async {
    const apiKey = 'apikey';
    const baseUrl =
        'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';
    // Fetching 50 records from Andhra Pradesh for relevant data
    final url =
        '$baseUrl?api-key=$apiKey&format=json&limit=50&filters[state]=Andhra Pradesh';

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List recordsJson = data['records'];

        if (!mounted) return;
        setState(() {
          _records = recordsJson
              .map((json) => MarketRecord.fromJson(json))
              .toList();
          _lastCheckedTime = DateFormat('HH:mm').format(DateTime.now());
        });
      } else {
        if (!mounted) return;
        setState(() => _errorMessage = 'Failed to load data.');
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Connection error. Check internet.');
      print('Network Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF), // Alice Blue
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      _buildMarketHeader(),
                      const SizedBox(height: 16),
                      _buildContent(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search Crops!!',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.notifications_outlined, color: Colors.grey),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(
              'assets/images/pfp.png',
            ), // Yahan image add ki
            backgroundColor: Color(
              0xFFE0E0E0,
            ), // Fallback color agar image load na ho
          ),
        ],
      ),
    );
  }

  Widget _buildMarketHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Market Prices',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastCheckedTime,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _fetchMarketData,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage.isNotEmpty) {
      return Expanded(child: Center(child: Text(_errorMessage)));
    }
    return Expanded(
      child: ListView.builder(
        itemCount: _records.length,
        itemBuilder: (context, index) {
          return _buildPriceListItem(_records[index]);
        },
      ),
    );
  }

  Widget _buildPriceListItem(MarketRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.commodity.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rs. ${record.minPrice} / quintal',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ],
            ),
            Text(
              'Rs. ${record.modalPrice}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
