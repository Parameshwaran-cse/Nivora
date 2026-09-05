class Location {
  final String id;
  final String name;
  final String type; // lab / cafeteria / dept / amenity / cabin-block
  final String building;
  final String floor;
  final double? mapX; // normalized 0.0-1.0, optional for future use
  final double? mapY; // normalized 0.0-1.0, optional for future use
  final String? description;

  Location({
    required this.id,
    required this.name,
    required this.type,
    required this.building,
    required this.floor,
    this.mapX,
    this.mapY,
    this.description,
  });

  factory Location.fromMap(String id, Map<String, dynamic> map) {
    return Location(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      building: map['building'] ?? 'Unspecified',
      floor: map['floor'] ?? 'Unspecified',
      mapX: map['mapX']?.toDouble(),
      mapY: map['mapY']?.toDouble(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'building': building,
      'floor': floor,
      'mapX': mapX,
      'mapY': mapY,
      'description': description,
    };
  }
}