import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Section
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/pfp.png'),
            ),
            const SizedBox(height: 16),
            Text(
              'Isha B',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Amaravati, Andhra Pradesh',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const Divider(height: 48),

            // Emergency Toolkit Section (Placeholder)
            Text(
              'Emergency Toolkit',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmergencyButton(
                  icon: Icons.call,
                  label: 'Call\nEmergency',
                  onTap: () {
                    print("Emergency Call button tapped (Placeholder).");
                  },
                  color: Colors.green.shade700,
                ),
                _buildEmergencyButton(
                  icon: Icons.flashlight_on,
                  label: 'SOS\nFlash',
                  onTap: () {
                    print("SOS Flash button tapped (Placeholder).");
                  },
                  color: Colors.blue.shade800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget ab stateful logic use nahi karta
  Widget _buildEmergencyButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
