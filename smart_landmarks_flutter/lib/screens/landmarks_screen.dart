import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/landmark_provider.dart';
import '../models/landmark.dart';

/// Landmarks List Screen - Shows landmarks in a scrollable list.
/// Features:
/// - Sort by score (ascending/descending toggle)
/// - Filter by minimum score (slider)
/// - Pull to refresh
/// - Visit & Delete buttons
class LandmarksScreen extends StatelessWidget {
  const LandmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LandmarkProvider>();

    return Column(
      children: [
        // ===== Sort & Filter Bar =====
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              // Sort Button
              ActionChip(
                avatar: Icon(
                  provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                ),
                label: Text('Score ${provider.sortAscending ? "↑" : "↓"}'),
                onPressed: () => provider.toggleSort(),
              ),
              const SizedBox(width: 12),
              // Min Score Label
              const Text('Min:', style: TextStyle(fontSize: 13)),
              // Min Score Slider
              Expanded(
                child: Slider(
                  value: provider.minScore.clamp(-2000000, 2000000),
                  min: -2000000,
                  max: 2000000,
                  divisions: 200,
                  label: provider.minScore.toInt().toString(),
                  onChanged: (value) => provider.setMinScore(value),
                ),
              ),
              Text('${provider.minScore.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // ===== Landmarks List =====
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.filteredLandmarks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.landscape, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No landmarks found',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadLandmarks(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: provider.filteredLandmarks.length,
                        itemBuilder: (ctx, index) {
                          final landmark = provider.filteredLandmarks[index];
                          return _LandmarkCard(landmark: landmark);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

/// Landmark card widget
class _LandmarkCard extends StatelessWidget {
  final Landmark landmark;
  const _LandmarkCard({required this.landmark});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LandmarkProvider>();

    // Score color (handles negative scores from server)
    Color scoreColor;
    if (landmark.score > 0) {
      scoreColor = Colors.green;
    } else if (landmark.score == 0) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: landmark.image != null && landmark.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: landmark.image!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.landscape, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(landmark.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '⭐ Score: ${landmark.score.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, color: scoreColor, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '👁 Visits: ${landmark.visitCount} | Avg: ${(landmark.avgDistance / 1000).toStringAsFixed(1)} km',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  // Action Buttons
                  Row(
                    children: [
                      // Visit Button
                      SizedBox(
                        height: 30,
                        child: ElevatedButton.icon(
                          onPressed: () => _visitLandmark(context, landmark, provider),
                          icon: const Icon(Icons.directions_walk, size: 14),
                          label: const Text('Visit', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete Button
                      SizedBox(
                        height: 30,
                        child: TextButton(
                          onPressed: () => _confirmDelete(context, landmark, provider),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _visitLandmark(BuildContext context, Landmark landmark, LandmarkProvider provider) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        await provider.visitLandmark(landmark, position.latitude, position.longitude);
      } else {
        // Fallback
        await provider.visitLandmark(landmark, landmark.lat, landmark.lon);
      }
    } catch (e) {
      await provider.visitLandmark(landmark, landmark.lat, landmark.lon);
    }
  }

  void _confirmDelete(BuildContext context, Landmark landmark, LandmarkProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Landmark'),
        content: Text('Are you sure you want to delete "${landmark.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteLandmark(landmark.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
