import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Data ko hold karne ke liye ek model

class BreedingRecommendation {
  final String recommendedbreedingmutation;
  final String recommendedTrait;
  final String reason;
  final String suggestedAction;

  BreedingRecommendation({
    required this.recommendedbreedingmutation,
    required this.recommendedTrait,
    required this.reason,
    required this.suggestedAction,
  });

  factory BreedingRecommendation.fromJson(Map<String, dynamic> json) {
    return BreedingRecommendation(
      recommendedbreedingmutation:
          json['recommended_breeding/mutation'] ?? 'N/A',
      recommendedTrait: json['recommended_trait'] ?? 'N/A',
      reason: json['reason'] ?? 'No reason provided.',
      suggestedAction: json['suggested_action'] ?? 'No action suggested.',
    );
  }
}

class FarmData {
  final double temp1;
  final double temp2;
  final double humidity;

  FarmData({required this.temp1, required this.temp2, required this.humidity});

  // JSON se object banane ke liye
  factory FarmData.fromJson(Map<String, dynamic> json) {
    return FarmData(
      temp1: (json['temp1'] as num).toDouble(),
      temp2: (json['temp2'] as num).toDouble(),
      humidity: (json['hum'] as num).toDouble(),
    );
  }

  // Object se JSON banane ke liye
  Map<String, dynamic> toJson() {
    return {'temp1': temp1, 'temp2': temp2, 'hum': humidity};
  }
}

// 2. State ko manage karne ke liye Notifier
class FarmDataNotifier extends StateNotifier<Map<String, FarmData>> {
  FarmDataNotifier() : super({});

  // Phone ki memory se saara data load karega
  Future<void> loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    Map<String, FarmData> loadedData = {};

    for (String key in keys) {
      if (key.endsWith('_data')) {
        final String? jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final areaName = key.replaceAll('_data', '');
            loadedData[areaName] = FarmData.fromJson(json.decode(jsonString));
          } catch (e) {
            print("Could not parse cached data for key $key: $e");
          }
        }
      }
    }
    state = loadedData;
    print("✅ All farm data loaded from memory.");
  }

  // Kisi ek area ka data update karega aur memory mein save karega
  Future<void> updateAreaData(String areaName, FarmData newData) async {
    final prefs = await SharedPreferences.getInstance();
    state = {...state, areaName: newData}; // In-memory state update
    await prefs.setString(
      '${areaName}_data',
      json.encode(newData.toJson()),
    ); // Phone memory update
    print("💾 Updated and saved data for $areaName");
  }
}

// 3. Poore app mein is data ko access karne ke liye Provider
final farmDataProvider =
    StateNotifierProvider<FarmDataNotifier, Map<String, FarmData>>((ref) {
      return FarmDataNotifier();
    });
