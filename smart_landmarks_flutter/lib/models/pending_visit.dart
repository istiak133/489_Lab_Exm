/// Pending Visit model - stored locally when offline.
/// Synced to server when internet comes back.
class PendingVisit {
  final int? id;
  final int landmarkId;
  final String landmarkName;
  final double userLat;
  final double userLon;
  final int timestamp;

  PendingVisit({
    this.id,
    required this.landmarkId,
    required this.landmarkName,
    required this.userLat,
    required this.userLon,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'landmarkId': landmarkId,
      'landmarkName': landmarkName,
      'userLat': userLat,
      'userLon': userLon,
      'timestamp': timestamp,
    };
  }

  factory PendingVisit.fromMap(Map<String, dynamic> map) {
    return PendingVisit(
      id: map['id'] as int?,
      landmarkId: map['landmarkId'] as int,
      landmarkName: map['landmarkName'] as String,
      userLat: (map['userLat'] as num).toDouble(),
      userLon: (map['userLon'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
    );
  }
}
