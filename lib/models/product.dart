// models/product.dart
import 'package:mongo_dart/mongo_dart.dart';

class Product {
  final ObjectId id;
  final ObjectId stationId;
  String name;
  String type;
  double price;
  String unit;
  String description;
  String status;
  DateTime createdAt;
  DateTime updatedAt;

  Product({
    ObjectId? id,
    required this.stationId,
    required this.name,
    required this.type,
    required this.price,
    this.unit = 'lít',
    this.description = '',
    this.status = 'available',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? ObjectId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['_id'],
      stationId: map['stationId'],
      name: map['name'],
      type: map['type'],
      price: map['price']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'lít',
      description: map['description'] ?? '',
      status: map['status'] ?? 'available',
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
      'stationId': stationId,
      'name': name,
      'type': type,
      'price': price,
      'unit': unit,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}