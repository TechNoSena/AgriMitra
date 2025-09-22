import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'ai_assistant_viewmodel.dart';

class PlantDoctorPage extends StatelessWidget {
  const PlantDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiAssistantViewModel(),
      child: const _PlantDoctorView(),
    );
  }
}

class _PlantDoctorView extends StatefulWidget {
  const _PlantDoctorView();

  @override
  State<_PlantDoctorView> createState() => _PlantDoctorViewState();
}

class _PlantDoctorViewState extends State<_PlantDoctorView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AiAssistantViewModel>(context);

    if (viewModel.chatHistory.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Farm Doctor 🩺',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                children: [
                  GestureDetector(
                    onTap: () => _showImagePickerOptions(context, viewModel),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: viewModel.selectedImage == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 40,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap to upload photo",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    viewModel.selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: viewModel.clearImage,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...viewModel.chatHistory
                      .map((msg) => _buildMessageCard(msg))
                      .toList(),

                  if (viewModel.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),

            _buildTextInput(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    bool isUser = message['role'] == 'user';
    bool isTyping = message['role'] == 'typing';

    if (isTyping) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Farm Doctor is thinking...",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUser ? "You Asked:" : "Farm Doctor Replied:",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (message['image'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                message['image'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (message['question'] != null)
            Text(
              message['question'],
              style: GoogleFonts.poppins(fontStyle: FontStyle.italic),
            ),
          if (message['response'] != null)
            Text(message['response'], style: GoogleFonts.poppins(height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildTextInput(AiAssistantViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              viewModel.isListening ? Icons.mic : Icons.mic_none,
              color: const Color(0xFF2C3E50),
            ),
            onPressed: () => viewModel.toggleListening((text) {
              _textController.text = text;
            }),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ask about the plant...",
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(),
              ),
              onSubmitted: (text) => _sendMessage(viewModel),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF2C3E50)),
            onPressed: viewModel.isLoading
                ? null
                : () => _sendMessage(viewModel),
          ),
        ],
      ),
    );
  }

  // MODIFIED: Ab yeh seedha `sendMessage` ko call karega
  void _sendMessage(AiAssistantViewModel viewModel) {
    viewModel.sendMessage(
      // `showAdAndSendMessage` ki jagah
      text: _textController.text,
      languageCode: 'en',
    );
    _textController.clear();
  }

  void _showImagePickerOptions(
    BuildContext context,
    AiAssistantViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text("Take Photo", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.of(context).pop();
                viewModel.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text("Choose from Gallery", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.of(context).pop();
                viewModel.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
