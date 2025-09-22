import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'help_page.dart'; // HelpPage ko import karein

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'About AgroAI',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        // --- NAYA: Top right corner mein button add kiya ---
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.grey.shade700),
            tooltip: 'Help & FAQs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              );
            },
          ),
          const SizedBox(width: 16), // Thodi spacing ke liye
        ],
        // ---------------------------------------------------
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/images/app_logo1.png',
                height: 120,
              ), // logo ka naam theek kar diya
              const SizedBox(height: 16),
              Text(
                'AgroAI',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              Text(
                'Version 1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // App Description
              Text(
                'Empowering modern farming with the power of AI and Automation. Our rover provides real-time soil data, helping you make smarter decisions for healthier crops and better yields.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const Divider(height: 48, thickness: 1),

              // Key Features
              Text(
                'Key Features',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureTile(
                icon: Icons.agriculture,
                title: 'Rover Control & Automation',
                subtitle: 'Deploy and control your rover remotely.',
              ),
              _buildFeatureTile(
                icon: Icons.wb_sunny_outlined,
                title: 'Live Weather Updates',
                subtitle: 'Get real-time weather data for your location.',
              ),
              _buildFeatureTile(
                icon: Icons.biotech,
                title: 'AI Crop Prediction',
                subtitle: 'Receive crop recommendations based on soil data.',
              ),
              _buildFeatureTile(
                icon: Icons.area_chart_outlined,
                title: 'Farm Area Management',
                subtitle: 'Manage and monitor multiple farm areas.',
              ),

              const SizedBox(height: 32),

              // Footer
              Text(
                'Made with ❤️ using Isha ke Tekskilzz',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for feature list tiles
  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.blue.shade700),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 14)),
      ),
    );
  }
}
