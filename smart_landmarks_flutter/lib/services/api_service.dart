import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/landmark.dart';

/// API Service - Handles all 5 REST API endpoints.
///
/// Base URL: https://labs.anontech.info/cse489/exm3/api.php
///
class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/exm3/api.php';

  // ===== CHANGE THIS TO YOUR STUDENT KEY =====
  static const String studentKey = '24141210';
  // ============================================

  /// Endpoint 1: GET - Fetch all landmarks
  Future<List<Landmark>> getLandmarks() async {
    final uri = Uri.parse('$baseUrl?action=get_landmarks&key=$studentKey');
    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((json) => Landmark.fromJson(json)).toList();
      } else if (decoded is Map && decoded.containsKey('data') && decoded['data'] is List) {
        return (decoded['data'] as List).map((json) => Landmark.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load landmarks: ${response.statusCode}');
    }
  }

  /// Endpoint 2: POST - Visit a landmark (JSON body)
  /// Returns distance from server
  Future<Map<String, dynamic>> visitLandmark({
    required int landmarkId,
    required double userLat,
    required double userLon,
  }) async {
    final uri = Uri.parse('$baseUrl?action=visit_landmark&key=$studentKey');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'landmark_id': landmarkId,
        'user_lat': userLat,
        'user_lon': userLon,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Visit failed: ${response.statusCode}');
    }
  }

  /// Endpoint 3: POST - Create a new landmark (form-data with image!)
  /// ⚠️ MUST use multipart/form-data, NOT raw JSON! (PDF warns explicitly)
  Future<Map<String, dynamic>> createLandmark({
    required String title,
    required double lat,
    required double lon,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl?action=create_landmark&key=$studentKey');
    final request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Create failed: ${response.statusCode}');
    }
  }

  /// Endpoint 4: POST - Soft delete a landmark (form-data)
  Future<Map<String, dynamic>> deleteLandmark(int id) async {
    final uri = Uri.parse('$baseUrl?action=delete_landmark&key=$studentKey');
    final response = await http.post(
      uri,
      body: {'id': id.toString()},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }

  /// Endpoint 5: POST - Restore a soft-deleted landmark (form-data)
  Future<Map<String, dynamic>> restoreLandmark(int id) async {
    final uri = Uri.parse('$baseUrl?action=restore_landmark&key=$studentKey');
    final response = await http.post(
      uri,
      body: {'id': id.toString()},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Restore failed: ${response.statusCode}');
    }
  }
}
