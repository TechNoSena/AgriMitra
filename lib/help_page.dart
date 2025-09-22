import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

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
          'Help & FAQs',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Using ExpansionTile for collapsible sections, which is great for FAQs
              _buildSectionTile(
                title: 'Getting Started: Rover Connection',
                icon: Icons.bluetooth_connected,
                children: [
                  _buildFaqItem(
                    question: 'Rover ko app se kaise connect karein?',
                    answer:
                        '1. Sabse pehle, phone ka Bluetooth aur Rover dono ON karein.\n'
                        '2. App mein neeche diye gaye "Rover" tab par jayein.\n'
                        '3. Screen par dikh rahe bade se "Connect" button ko dabayein.\n'
                        '4. App background mein aapke Rover ko dhoondh kar automatically connect kar lega. Connect hone par battery indicator dikhega.',
                  ),
                ],
              ),

              _buildSectionTile(
                title: 'Home Page Guide',
                icon: Icons.home_outlined,
                children: [
                  _buildFaqItem(
                    question: 'Weather card kya batata hai?',
                    answer:
                        'Weather card aapke current location (Amaravati) ka live mausam, taapman (temperature), aur nami (humidity) dikhata hai.',
                  ),
                  _buildFaqItem(
                    question: 'Crop AI section kya hai?',
                    answer:
                        'Yeh section aapke Rover dwara bheje gaye soil data ke aadhar par Machine Learning model se predict ki gayi fasal (crop) ka naam aur confidence score dikhata hai.',
                  ),
                ],
              ),

              _buildSectionTile(
                title: 'Control Panel Guide',
                icon: Icons.gamepad_outlined,
                children: [
                  _buildFaqItem(
                    question: 'Remote Control kaise use karein?',
                    answer:
                        'Control Panel par bane arrows (↑, ↓, ←, →) se aap Rover ko aage, peeche, left, aur right ghuma sakte hain. Beech mein bana laal button (■) Rover ko turant rokne ke liye hai.',
                  ),
                  _buildFaqItem(
                    question: 'Deploy/Undeploy Sensor button ka kya kaam hai?',
                    answer:
                        'Yeh button Rover par lage sensor ko deploy (khet mein lagane) aur undeploy (wapas upar lene) ke liye command bhejta hai.',
                  ),
                  _buildFaqItem(
                    question:
                        'Soil Health ke aage Refresh button ka kya kaam hai?',
                    answer:
                        'Is button ko dabane se app, Rover ko naya sensor data (temperature, humidity) bhejne ka command deta hai. Naya data aate hi screen par values update ho jaati hain aur nayi fasal predict hoti hai.',
                  ),
                ],
              ),

              _buildSectionTile(
                title: 'Troubleshooting (Aam Samasyaein)',
                icon: Icons.help_outline,
                children: [
                  _buildFaqItem(
                    question: 'Rover connect nahi ho raha, kya karun?',
                    answer:
                        'Yeh cheezein check karein:\n'
                        '1. Aapke phone ka Bluetooth ON hai.\n'
                        '2. Aapka ESP32 Rover ON hai aur uski light jal rahi hai.\n'
                        '3. App ko "Nearby devices" ki permission di gayi hai.\n'
                        '4. Rover aur phone ek doosre ke paas hain.',
                  ),
                  _buildFaqItem(
                    question:
                        'Sensor data "--°C" dikha raha hai, update nahi ho raha.',
                    answer:
                        'Iska matlab hai ki Rover se naya data abhi tak nahi aaya hai. Control Panel par "Soil Health" ke saamne bane Refresh (🔄) icon ko dabayein. Agar Rover connected hai to data update ho jayega.',
                  ),
                  _buildFaqItem(
                    question: 'Temperature 2 mein -15°C kyun dikhata hai?',
                    answer:
                        'Yeh ek calculation hai. Asli value ESP32 se aati hai, jismein se hum 15 minus karke dikhate hain. Agar ESP32 se 0 aata hai, to yeh -15 dikhega.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for a styled section
  Widget _buildSectionTile({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.blue.shade800),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        children: children,
      ),
    );
  }

  // Helper widget for a single FAQ item
  Widget _buildFaqItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sawal: $question',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jawab: $answer',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
