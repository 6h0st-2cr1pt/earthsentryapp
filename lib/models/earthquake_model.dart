class EarthquakeModel {
  final String id;
  final String locationName;
  final double magnitude;
  final double? intensity;
  final double depth;
  final DateTime time;
  final double latitude;
  final double longitude;
  final String? tsunamiWarning;
  final String? source;

  EarthquakeModel({
    required this.id,
    required this.locationName,
    required this.magnitude,
    this.intensity,
    required this.depth,
    required this.time,
    required this.latitude,
    required this.longitude,
    this.tsunamiWarning,
    this.source,
  });

  factory EarthquakeModel.fromUSGSJson(Map<String, dynamic> json) {
    final properties = json['properties'] ?? {};
    final geometry = json['geometry'] ?? {};
    final coordinates = geometry['coordinates'] ?? [];
    
    return EarthquakeModel(
      id: json['id'] ?? '',
      locationName: properties['place'] ?? 'Unknown',
      magnitude: (properties['mag'] ?? 0.0).toDouble(),
      depth: coordinates.length > 2 ? (coordinates[2] ?? 0.0).toDouble() : 0.0,
      time: DateTime.fromMillisecondsSinceEpoch(
        properties['time'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      latitude: coordinates.length > 1 ? (coordinates[1] ?? 0.0).toDouble() : 0.0,
      longitude: coordinates.length > 0 ? (coordinates[0] ?? 0.0).toDouble() : 0.0,
      source: 'USGS',
    );
  }

  factory EarthquakeModel.fromPHIVOLCS({
    required String locationName,
    required double magnitude,
    double? intensity,
    required double depth,
    required DateTime time,
    required double latitude,
    required double longitude,
    String? tsunamiWarning,
  }) {
    return EarthquakeModel(
      id: 'phivolcs_${time.millisecondsSinceEpoch}',
      locationName: locationName,
      magnitude: magnitude,
      intensity: intensity,
      depth: depth,
      time: time,
      latitude: latitude,
      longitude: longitude,
      tsunamiWarning: tsunamiWarning,
      source: 'PHIVOLCS',
    );
  }

  String getSeverityLevel() {
    if (magnitude < 2.0) return 'Low';
    if (magnitude < 4.0) return 'Moderate';
    if (magnitude < 6.0) return 'High';
    if (magnitude < 8.0) return 'Extreme';
    return 'Extreme';
  }

  int getMagnitudeColor() {
    if (magnitude < 2.0) return 0xFF1B2A30; // Slate Blue
    if (magnitude < 3.0) return 0xFF305853; // Deep Teal
    if (magnitude < 4.0) return 0xFF4CAF50; // Sea Green
    if (magnitude < 5.0) return 0xFFB06821; // Golden Amber
    if (magnitude < 6.0) return 0xFFFFD53D; // Sunburst Yellow
    if (magnitude < 7.0) return 0xFFFF8C00; // Burnt Orange
    if (magnitude < 8.0) return 0xFF9E2C21; // Brick Red
    if (magnitude < 9.0) return 0xFF511B18; // Dark Mahogany
    if (magnitude < 9.5) return 0xFFD00000; // Fiery Red
    return 0xFFFF0000; // Pure Red
  }
}

