import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/landmark.dart';
import '../models/visit_history.dart';
import '../models/pending_visit.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

/// LandmarkProvider - Central state management (like ViewModel in Android).
/// Manages: landmarks, visit history, offline queue, sort/filter state.
class LandmarkProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();

  // State
  List<Landmark> _landmarks = [];
  List<Landmark> _filteredLandmarks = [];
  List<VisitHistory> _visitHistory = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String? _message;
  int _pendingCount = 0;

  // Sort/Filter
  bool _sortAscending = false;
  double _minScore = -2000000;

  // Getters
  List<Landmark> get landmarks => _landmarks;
  List<Landmark> get filteredLandmarks => _filteredLandmarks;
  List<VisitHistory> get visitHistory => _visitHistory;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get message => _message;
  int get pendingCount => _pendingCount;
  bool get sortAscending => _sortAscending;
  double get minScore => _minScore;

  /// Load landmarks from API (online) or SQLite cache (offline).
  Future<void> loadLandmarks() async {
    _isLoading = true;
    notifyListeners();

    // Check internet connectivity
    final connectivity = await Connectivity().checkConnectivity();
    _isOffline = connectivity == ConnectivityResult.none;

    try {
      if (!_isOffline) {
        // Online: Fetch from API
        final apiLandmarks = await _apiService.getLandmarks();
        _landmarks = apiLandmarks;
        // Cache to SQLite
        await _dbService.cacheLandmarks(apiLandmarks);
        // Sync pending visits
        await _syncPendingVisits();
      } else {
        // Offline: Load from cache
        _landmarks = await _dbService.getCachedLandmarks();
      }
      _applyFilterAndSort();
    } catch (e) {
      // On error, try cache
      _landmarks = await _dbService.getCachedLandmarks();
      _applyFilterAndSort();
      _message = 'Error loading: ${e.toString()}';
    }

    // Load visit history
    _visitHistory = await _dbService.getVisitHistory();
    _pendingCount = await _dbService.getPendingVisitCount();

    _isLoading = false;
    notifyListeners();
  }

  /// Visit a landmark with GPS coordinates.
  Future<void> visitLandmark(Landmark landmark, double userLat, double userLon) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      
      if (connectivity != ConnectivityResult.none) {
        // Online: Send visit request to API
        final response = await _apiService.visitLandmark(
          landmarkId: landmark.id,
          userLat: userLat,
          userLon: userLon,
        );

        final distance = _parseDouble(response['distance']);
        
        // Save to visit history
        await _dbService.insertVisitHistory(VisitHistory(
          landmarkId: landmark.id,
          landmarkName: landmark.title,
          visitTime: DateTime.now().millisecondsSinceEpoch,
          distance: distance,
          userLat: userLat,
          userLon: userLon,
        ));

        _message = '✅ Visited ${landmark.title}! Distance: ${distance.toStringAsFixed(2)} km';
        
        // Refresh data
        await loadLandmarks();
      } else {
        // Offline: Queue for later sync
        await _dbService.insertPendingVisit(PendingVisit(
          landmarkId: landmark.id,
          landmarkName: landmark.title,
          userLat: userLat,
          userLon: userLon,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
        _pendingCount = await _dbService.getPendingVisitCount();
        _message = '📡 Visit queued. Will sync when online.';
        notifyListeners();
      }
    } catch (e) {
      // On error, queue offline
      await _dbService.insertPendingVisit(PendingVisit(
        landmarkId: landmark.id,
        landmarkName: landmark.title,
        userLat: userLat,
        userLon: userLon,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
      _pendingCount = await _dbService.getPendingVisitCount();
      _message = '📡 Visit queued (network error). Will sync when online.';
      notifyListeners();
    }
  }

  /// Create a new landmark with image upload.
  Future<void> createLandmark(String title, double lat, double lon, File imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.createLandmark(
        title: title,
        lat: lat,
        lon: lon,
        imageFile: imageFile,
      );
      _message = '✅ Landmark "$title" created successfully!';
      await loadLandmarks();
    } catch (e) {
      _message = '❌ Create failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Soft delete a landmark.
  Future<void> deleteLandmark(int id) async {
    try {
      await _apiService.deleteLandmark(id);
      _message = '🗑️ Landmark deleted.';
      await loadLandmarks();
    } catch (e) {
      _message = '❌ Delete failed: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Restore a soft-deleted landmark.
  Future<void> restoreLandmark(int id) async {
    try {
      await _apiService.restoreLandmark(id);
      _message = '♻️ Landmark restored.';
      await loadLandmarks();
    } catch (e) {
      _message = '❌ Restore failed: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sort by score
  void toggleSort() {
    _sortAscending = !_sortAscending;
    _applyFilterAndSort();
    notifyListeners();
  }

  /// Filter by minimum score
  void setMinScore(double score) {
    _minScore = score;
    _applyFilterAndSort();
    notifyListeners();
  }

  /// Apply current sort and filter settings
  void _applyFilterAndSort() {
    var result = _landmarks.where((l) => l.score >= _minScore).toList();
    if (_sortAscending) {
      result.sort((a, b) => a.score.compareTo(b.score));
    } else {
      result.sort((a, b) => b.score.compareTo(a.score));
    }
    _filteredLandmarks = result;
  }

  /// Sync all pending offline visits to server.
  Future<void> _syncPendingVisits() async {
    final pending = await _dbService.getPendingVisits();
    for (final visit in pending) {
      try {
        final response = await _apiService.visitLandmark(
          landmarkId: visit.landmarkId,
          userLat: visit.userLat,
          userLon: visit.userLon,
        );
        // Save to history
        await _dbService.insertVisitHistory(VisitHistory(
          landmarkId: visit.landmarkId,
          landmarkName: visit.landmarkName,
          visitTime: visit.timestamp,
          distance: _parseDouble(response['distance']),
          userLat: visit.userLat,
          userLon: visit.userLon,
        ));
        // Remove from queue
        if (visit.id != null) {
          await _dbService.deletePendingVisit(visit.id!);
        }
      } catch (e) {
        // Keep in queue if sync fails
        debugPrint('Sync failed for visit ${visit.id}: $e');
      }
    }
    _pendingCount = await _dbService.getPendingVisitCount();
  }

  /// Clear message after showing
  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
