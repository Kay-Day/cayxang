import 'package:mongo_dart/mongo_dart.dart';

class OrderItem {
  final ObjectId productId;
  final String name;
  final double price;
  final double quantity;
  final double total;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'],
      name: map['name'],
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}

class Order {
  final ObjectId id;
  final String orderCode;
  final ObjectId customerId;
  final ObjectId stationId;
  final List<OrderItem> products;
  final double totalAmount;
  final int earnedPoints;
  String status;
  final String paymentMethod;
  DateTime createdAt;
  DateTime updatedAt;

  Order({
    ObjectId? id,
    required this.orderCode,
    required this.customerId,
    required this.stationId,
    required this.products,
    required this.totalAmount,
    required this.earnedPoints,
    this.status = 'pending',
    required this.paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? ObjectId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['_id'],
      orderCode: map['orderCode'],
      customerId: map['customerId'],
      stationId: map['stationId'],
      products: List<OrderItem>.from(
          map['products']?.map((x) => OrderItem.fromMap(x)) ?? []),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      earnedPoints: map['earnedPoints'] ?? 0,
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'],
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
      'orderCode': orderCode,
      'customerId': customerId,
      'stationId': stationId,
      'products': products.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'earnedPoints': earnedPoints,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}