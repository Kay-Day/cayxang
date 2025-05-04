// models/user.dart
import 'package:mongo_dart/mongo_dart.dart';

enum UserRole { customer, owner }

class User {
  final ObjectId id;
  final String email;
  String password;
  String fullName;
  String phoneNumber;
  String address;
  UserRole role;
  int points;
  DateTime createdAt;
  DateTime updatedAt;

  User({
    ObjectId? id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.role,
    this.points = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? ObjectId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'],
      email: map['email'],
      password: map['password'],
      fullName: map['fullName'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      role: map['role'] == 'owner' ? UserRole.owner : UserRole.customer,
      points: map['points'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'email': email,
      'password': password,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'role': role == UserRole.owner ? 'owner' : 'customer',
      'points': points,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}