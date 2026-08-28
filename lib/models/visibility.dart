class Visibility {
  final bool name;
  final bool photo;
  final bool department;
  final bool cabinNo;
  final bool phone;
  final bool email;

  Visibility({
    this.name = true,
    this.photo = true,
    this.department = true,
    this.cabinNo = true,
    this.phone = false,
    this.email = true,
  });

  factory Visibility.fromMap(Map<String, dynamic> map) {
    return Visibility(
      name: map['name'] ?? true,
      photo: map['photo'] ?? true,
      department: map['department'] ?? true,
      cabinNo: map['cabinNo'] ?? true,
      phone: map['phone'] ?? false,
      email: map['email'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photo': photo,
      'department': department,
      'cabinNo': cabinNo,
      'phone': phone,
      'email': email,
    };
  }
}