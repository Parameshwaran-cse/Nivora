class Department {
  final String id;
  final String name;
  final String shortCode;

  Department({
    required this.id,
    required this.name,
    required this.shortCode,
  });

  factory Department.fromMap(String id, Map<String, dynamic> map) {
    return Department(
      id: id,
      name: map['name'] ?? '',
      shortCode: map['shortCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortCode': shortCode,
    };
  }
}