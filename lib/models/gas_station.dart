import 'package:mongo_dart/mongo_dart.dart' as mongo;

class GasStation {
  final mongo.ObjectId id;
  final mongo.ObjectId ownerId;
  final String name;
  final String address;
  final String district;
  final String city;
  final String phoneNumber;
  final String? description;
  final List<String> services;
  final List<String> images;
  final String status;

  GasStation({
    mongo.ObjectId? id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.phoneNumber,
    this.description,
    required this.services,
    required this.images,
    this.status = 'active',
  }) : this.id = id ?? mongo.ObjectId();

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'district': district,
      'city': city,
      'phoneNumber': phoneNumber,
      'description': description,
      'services': services,
      'images': images,
      'status': status,
    };
  }

  factory GasStation.fromMap(Map<String, dynamic> map) {
    return GasStation(
      id: map['_id'] as mongo.ObjectId,
      ownerId: map['ownerId'] as mongo.ObjectId,
      name: map['name'] as String,
      address: map['address'] as String,
      district: map['district'] as String,
      city: map['city'] as String,
      phoneNumber: map['phoneNumber'] as String,
      description: map['description'] as String?,
      services: List<String>.from(map['services']),
      images: List<String>.from(map['images']),
      status: map['status'] as String,
    );
  }

  GasStation copyWith({
    mongo.ObjectId? id,
    mongo.ObjectId? ownerId,
    String? name,
    String? address,
    String? district,
    String? city,
    String? phoneNumber,
    String? description,
    List<String>? services,
    List<String>? images,
    String? status,
  }) {
    return GasStation(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      district: district ?? this.district,
      city: city ?? this.city,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
      services: services ?? this.services,
      images: images ?? this.images,
      status: status ?? this.status,
    );
  }
}