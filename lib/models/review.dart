// models/review.dart
import 'package:mongo_dart/mongo_dart.dart';

class Review {
  final ObjectId id;
  final ObjectId stationId;
  final ObjectId customerId;
  final String customerName;
  final int rating; // 1-5 sao
  final String comment;
  final DateTime createdAt;

  Review({
    ObjectId? id,
    required this.stationId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment = '',
    DateTime? createdAt,
  }) : id = id ?? ObjectId(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'stationId': stationId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['_id'] as ObjectId,
      stationId: map['stationId'] as ObjectId,
      customerId: map['customerId'] as ObjectId,
      customerName: map['customerName'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}