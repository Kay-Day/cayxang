import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import 'database_service.dart';
import 'auth_service.dart';

class OrderService {
  final DatabaseService _dbService = DatabaseService();
  late AuthService _authService;
  final Uuid _uuid = Uuid();
  
  // Constructor để nhận AuthService từ bên ngoài
  OrderService({AuthService? authService}) {
    if (authService != null) {
      _authService = authService;
    } else {
      _authService = AuthService();
    }
  }
  
  // Tạo đơn hàng mới - sửa đổi để in thông tin debug
  Future<Order?> createOrder({
  required ObjectId stationId,
  required List<OrderItem> products,
  required double totalAmount,
  required String paymentMethod,
  int usedPoints = 0,
  double discount = 0,
})  async {
    try {
      // In thông tin để debug
      print('Đang tạo đơn hàng...');
      print('AuthService instance: $_authService');
      print('Người dùng hiện tại: ${_authService.currentUser}');
      
      if (_authService.currentUser == null) {
        print('Không thể tạo đơn hàng: Người dùng chưa đăng nhập');
        return null;
      }
      
      // Tính điểm thưởng (cứ 100,000 VND được 5 điểm)
      final earnedPoints = totalAmount >= 100000 ? (totalAmount / 100000 * 5).floor() : 0;
      
      // Tạo mã đơn hàng
      final orderCode = _generateOrderCode();
      
      print('Đang tạo đơn hàng với mã: $orderCode');
      print('Cho người dùng: ${_authService.currentUser!.fullName}');
      
      final order = Order(
        orderCode: orderCode,
        customerId: _authService.currentUser!.id,
        stationId: stationId,
        products: products,
        totalAmount: totalAmount,
        earnedPoints: earnedPoints,
        paymentMethod: paymentMethod,
      );
      
      // Lưu đơn hàng vào database
      print('Đang lưu đơn hàng vào database...');
      await _dbService.ordersCollection.insert(order.toMap());
      print('Đã lưu đơn hàng thành công!');
      
      // Cập nhật điểm cho người dùng
      if (earnedPoints > 0) {
        print('Cập nhật $earnedPoints điểm cho người dùng');
        await _authService.updatePoints(earnedPoints);
      }
      
      return order;
    } catch (e) {
      print('Lỗi tạo đơn hàng: $e');
      return null;
    }
  }
  
  // Lấy lịch sử đơn hàng của khách hàng
// Lấy lịch sử đơn hàng của khách hàng - phiên bản sửa đổi
Future<List<Order>> getCustomerOrders() async {
  try {
    if (_authService.currentUser == null) {
      print('Không thể lấy lịch sử đơn hàng: Người dùng chưa đăng nhập');
      return [];
    }
    
    print('Đang lấy lịch sử đơn hàng cho người dùng: ${_authService.currentUser!.id}');
    
    final orders = await _dbService.ordersCollection
        .find(where.eq('customerId', _authService.currentUser!.id))
        .toList();
    
    print('Số đơn hàng tìm thấy: ${orders.length}');
    
    return orders.map((order) => Order.fromMap(order)).toList();
  } catch (e) {
    print('Lỗi lấy lịch sử đơn hàng: $e');
    return [];
  }
}
  
  // Lấy đơn hàng của cửa hàng
  Future<List<Order>> getStationOrders(ObjectId stationId) async {
    try {
      final orders = await _dbService.ordersCollection
          .find(where.eq('stationId', stationId))
          .toList();
      
      return orders.map((order) => Order.fromMap(order)).toList();
    } catch (e) {
      print('Lỗi lấy đơn hàng cửa hàng: $e');
      return [];
    }
  }
  
  // Lấy đơn hàng theo mã
  Future<Order?> getOrderByCode(String orderCode) async {
    try {
      final order = await _dbService.ordersCollection
          .findOne(where.eq('orderCode', orderCode));
      
      if (order != null) {
        return Order.fromMap(order);
      }
      
      return null;
    } catch (e) {
      print('Lỗi lấy đơn hàng theo mã: $e');
      return null;
    }
  }
  
  // Cập nhật trạng thái đơn hàng
  Future<bool> updateOrderStatus(ObjectId orderId, String newStatus) async {
    try {
      await _dbService.ordersCollection.update(
        where.eq('_id', orderId),
        {
          '\$set': {
            'status': newStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          }
        }
      );
      
      return true;
    } catch (e) {
      print('Lỗi cập nhật trạng thái đơn hàng: $e');
      return false;
    }
  }
  
  // Tạo mã đơn hàng
  String _generateOrderCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    final randomCode = _uuid.v4().substring(0, 6);
    return 'XD$timestamp$randomCode'.toUpperCase();
  }
}