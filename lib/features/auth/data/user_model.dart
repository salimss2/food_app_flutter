import 'dart:convert';

class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? address;
  final String? location;

  UserModel({
    required this.name,
    required this.email,
    required this.password,
    this.id,
    this.phone,
    this.address,
    this.location,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'],
      address: json['address'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'address': address,
      'location': location,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      phone: map['phone'],
      address: map['address'],
      location: map['location'],
    );
  }

  String toJson() => json.encode(toMap());
  factory UserModel.fromJsonString(String source) => UserModel.fromJson(json.decode(source));
}