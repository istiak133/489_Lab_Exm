/// Visit History model - stored locally in SQLite.
/// Used for the Activity (Visit History) tab.
class VisitHistory {
  final int? id;
  final int landmarkId;
  final String landmarkName;
  final int visitTime; // milliseconds since epoch
  final double distance;
  final double userLat;
  final double userLon;

  VisitHistory({
    this.id,
    required this.landmarkId,
    required this.landmarkName,
    required this.visitTime,
    required this.distance,
    required this.userLat,
    required this.userLon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'landmarkId': landmarkId,
      'landmarkName': landmarkName,
      'visitTime': visitTime,
      'distance': distance,
      'userLat': userLat,
      'userLon': userLon,
    };
  }

  factory VisitHistory.fromMap(Map<String, dynamic> map) {
    return VisitHistory(
      id: map['id'] as int?,
      landmarkId: map['landmarkId'] as int,
      landmarkName: map['landmarkName'] as String,
      visitTime: map['visitTime'] as int,
      distance: (map['distance'] as num).toDouble(),
      userLat: (map['userLat'] as num).toDouble(),
      userLon: (map['userLon'] as num).toDouble(),
    );
  }
}
