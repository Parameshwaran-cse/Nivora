class Designation {
  final String id;
  final String title;
  final int rank;

  Designation({
    required this.id,
    required this.title,
    required this.rank,
  });

  factory Designation.fromMap(String id, Map<String, dynamic> map) {
    return Designation(
      id: id,
      title: map['title'] ?? '',
      rank: map['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'rank': rank,
    };
  }
}