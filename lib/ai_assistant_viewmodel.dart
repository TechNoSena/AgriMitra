import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AiAssistantViewModel extends ChangeNotifier {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<Map<String, dynamic>> _chatHistory = [];
  List<Map<String, dynamic>> get chatHistory => _chatHistory;

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  bool _isListening = false;
  bool get isListening => _isListening;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Ad-related variables hata diye gaye hain

  AiAssistantViewModel() {
    _initialize();
  }

  void _initialize() {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
    _chat = _model.startChat();
    _setupTts();
    // _loadRewardedAd() call hata diya gaya
  }

  Future<void> _setupTts() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  Future<void> toggleListening(Function(String) onResult) async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    } else {
      final available = await _speech.initialize();
      if (available) {
        _isListening = true;
        _speech.listen(
          localeId: "en_IN",
          onResult: (result) => onResult(result.recognizedWords),
        );
      }
    }
    notifyListeners();
  }

  // MODIFIED: Ab yeh public method hai aur ad ka logic nahi hai
  Future<void> sendMessage({
    required String text,
    required String languageCode,
  }) async {
    if ((text.isEmpty && _selectedImage == null) || _isLoading) return;

    _isLoading = true;
    final question = text.isNotEmpty ? text : null;
    final image = _selectedImage;
    notifyListeners();

    _chatHistory.add({'role': 'user', 'question': question, 'image': image});
    _chatHistory.add({'role': 'typing'});
    _selectedImage = null; // Image bhejne ke baad clear kar do
    notifyListeners();

    try {
      final prompt = _buildPrompt(text, languageCode);
      final content = await _buildContent(prompt, image);
      final response = await _chat.sendMessage(content);
      final reply = response.text ?? "Sorry, I couldn't process that.";

      _chatHistory.removeWhere((msg) => msg['role'] == 'typing');
      _chatHistory.add({'role': 'model', 'response': reply});
      _speak(reply);
    } catch (e) {
      _chatHistory.removeWhere((msg) => msg['role'] == 'typing');
      _chatHistory.add({
        'role': 'model',
        'response': '❌ Error: Failed to get a response.',
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _buildPrompt(String text, String languageCode) {
    final langLabel = languageCode == 'hi' ? 'Hindi' : 'English';
    final userQuery = text.isNotEmpty ? text : "Analyze this plant image.";
    return """
    You are an expert agricultural assistant named 'Farm Doctor'.
    Respond in a friendly, farmer-accessible tone in **$langLabel**.
    Keep responses concise and use bullet points with emojis.
    make it short sumarisable

    Format:
    - 🌿 Plant/Problem: Identify the plant or issue.
    - 💊 Solution: Suggest clear, simple, actionable steps.
    - ✨ Tip: Provide an extra helpful tip.

    User's query: "$userQuery"
    """;
  }

  Future<Content> _buildContent(String prompt, File? image) async {
    final parts = <Part>[TextPart(prompt)];
    if (image != null) {
      parts.insert(0, DataPart('image/jpeg', await image.readAsBytes()));
    }
    return Content.multi(parts);
  }

  // _loadRewardedAd() function poori tarah se hata diya gaya hai

  Future<void> _speak(String text) async {
    final lang = RegExp(r'[अ-ह]').hasMatch(text) ? "hi-IN" : "en-US";
    await _flutterTts.setLanguage(lang);
    await _flutterTts.speak(text.replaceAll(RegExp(r'[\\*]'), ''));
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    // _rewardedAd?.dispose() hata diya gaya
    super.dispose();
  }
}
