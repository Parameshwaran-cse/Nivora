class Location {
  final String id;
  final String name;
  final String type; // lab / cafeteria / dept / amenity / cabin-block
  final double mapX; // normalized 0.0-1.0
  final double mapY; // normalized 0.0-1.0
  final String? description;

  Location({
    required this.id,
    required this.name,
    required this.type,
    required this.mapX,
    required this.mapY,
    this.description,
  });

  factory Location.fromMap(String id, Map<String, dynamic> map) {
    return Location(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      mapX: (map['mapX'] ?? 0.0).toDouble(),
      mapY: (map['mapY'] ?? 0.0).toDouble(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'mapX': mapX,
      'mapY': mapY,
      'description': description,
    };
  }
}