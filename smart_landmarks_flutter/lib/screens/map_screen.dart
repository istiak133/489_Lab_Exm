import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/landmark_provider.dart';
import '../models/landmark.dart';

/// Map Screen - Shows all landmarks on OpenStreetMap.
/// Features:
/// - Score-based marker colors (red=low, green=high)
/// - Tap marker for details + visit option
/// - Centered on Bangladesh
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // Bangladesh center
  static const double bdLat = 23.685;
  static const double bdLon = 90.3563;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LandmarkProvider>();
    final landmarks = provider.landmarks;

    return SizedBox.expand(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(bdLat, bdLon),
          initialZoom: 7.5,
        ),
        children: [
          // OpenStreetMap tile layer (no API key!)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.smart_landmarks',
          ),
          // Landmark markers
          MarkerLayer(
            markers: landmarks.map((landmark) {
              return Marker(
                point: LatLng(landmark.lat, landmark.lon),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showLandmarkDialog(context, landmark, provider),
                  child: _buildMarker(landmark, landmarks),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build a colored marker based on score
  Widget _buildMarker(Landmark landmark, List<Landmark> allLandmarks) {
    final maxScore = allLandmarks.isNotEmpty
        ? allLandmarks.map((l) => l.score).reduce((a, b) => a > b ? a : b)
        : 1.0;
    final ratio = maxScore > 0 ? (landmark.score / maxScore).clamp(0.0, 1.0) : 0.5;

    // Red (low) → Yellow (mid) → Green (high)
    final color = Color.lerp(Colors.red, Colors.green, ratio) ?? Colors.blue;

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.3), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: const Icon(Icons.location_on, color: Colors.white, size: 24),
    );
  }

  /// Show landmark details dialog with Visit button
  void _showLandmarkDialog(BuildContext context, Landmark landmark, LandmarkProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(landmark.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (landmark.image != null && landmark.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    landmark.image!,
                    height: 150,
                    width: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text('⭐ Score: ${landmark.score.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
              Text('👁 Visits: ${landmark.visitCount}'),
              Text('📏 Avg Distance: ${(landmark.avgDistance / 1000).toStringAsFixed(2)} km'),
              Text('📍 Lat: ${landmark.lat.toStringAsFixed(4)}, Lon: ${landmark.lon.toStringAsFixed(4)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteLandmark(landmark.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _visitLandmark(context, landmark, provider);
            },
            icon: const Icon(Icons.directions_walk),
            label: const Text('Visit'),
          ),
        ],
      ),
    );
  }

  /// Visit landmark - get GPS then send request
  Future<void> _visitLandmark(BuildContext context, Landmark landmark, LandmarkProvider provider) async {
    try {
      // Check/request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied. Enable in Settings.')),
        );
        return;
      }

      // Get current position
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        // Fallback to last known
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          position = lastPosition;
        } else {
          // Use landmark's own coords as fallback (for testing)
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('GPS unavailable. Using approximate location.')),
            );
          }
          await provider.visitLandmark(landmark, landmark.lat, landmark.lon);
          return;
        }
      }

      await provider.visitLandmark(landmark, position.latitude, position.longitude);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }
}
