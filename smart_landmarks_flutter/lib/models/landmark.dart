/// Landmark model - Represents a single landmark from the API.
/// Also used for local SQLite caching.
///
/// API Response fields: id, title, lat, lon, image, score, visit_count, avg_distance
class Landmark {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String? image;
  final double score;
  final int visitCount;
  final double avgDistance;

  Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    this.image,
    required this.score,
    this.visitCount = 0,
    this.avgDistance = 0.0,
  });

  /// Parse from API JSON response
  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? 'Unknown',
      lat: _parseDouble(json['lat']),
      lon: _parseDouble(json['lon']),
      image: _buildImageUrl(json['image']?.toString()),
      score: _parseDouble(json['score']),
      visitCount: _parseInt(json['visit_count']),
      avgDistance: _parseDouble(json['avg_distance']),
    );
  }

  /// Convert to Map for SQLite insert
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
      'score': score,
      'visitCount': visitCount,
      'avgDistance': avgDistance,
    };
  }

  /// Parse from SQLite row
  factory Landmark.fromMap(Map<String, dynamic> map) {
    return Landmark(
      id: map['id'] as int,
      title: map['title'] as String,
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
      image: map['image'] as String?,
      score: (map['score'] as num).toDouble(),
      visitCount: (map['visitCount'] as num?)?.toInt() ?? 0,
      avgDistance: (map['avgDistance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Build full image URL from server's relative path.
  /// Server returns: "uploads/xxx.jpg" → we need: "https://labs.anontech.info/cse489/exm3/uploads/xxx.jpg"
  static String? _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return imagePath; // Already full URL
    return 'https://labs.anontech.info/cse489/exm3/$imagePath';
  }
}
