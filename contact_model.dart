// models/contact_model.dart
class Contact {
  int? id; // Nullable int for auto-incremented primary key
  String name;
  String phoneNumber;

  Contact({this.id, required this.name, required this.phoneNumber});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phoneNumber': phoneNumber};
  }

  factory Contact.fromMap(Map<dynamic, dynamic> map) {
    return Contact(
      id: map['id'] as int?, // Explicit cast to int?
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
    );
  }

}
