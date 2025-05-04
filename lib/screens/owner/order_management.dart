// screens/owner/order_management.dart
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/widget/invoice_widget.dart';
import 'package:xangdau_app/widget/order_card.dart';

import '../../services/order_service.dart';
import '../../services/auth_service.dart';

import '../../models/gas_station.dart';
import '../../models/order.dart';
import '../../models/user.dart';

class OrderManagementScreen extends StatefulWidget {
  final GasStation station;

  const OrderManagementScreen({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<mongo.ObjectId, User?> _customersCache = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getStationOrders(widget.station.id);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.generalError;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _orderService.updateOrderStatus(order.id, newStatus);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'completed'
                  ? 'Đơn hàng đã hoàn thành'
                  : 'Đơn hàng đã bị hủy',
            ),
            backgroundColor: newStatus == 'completed'
                ? Colors.green
                : Colors.orange,
          ),
        );
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trạng thái đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xảy ra lỗi. Vui lòng thử lại sau'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewOrderDetails(Order order) async {
    // Lấy thông tin khách hàng
    User? customer = await _getCustomerInfo(order.customerId);
    
    if (customer != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InvoiceWidget(
            order: order,
            station: widget.station,
            customer: customer,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tìm thấy thông tin khách hàng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<User?> _getCustomerInfo(mongo.ObjectId customerId) async {
    if (_customersCache.containsKey(customerId)) {
      return _customersCache[customerId];
    }

    try {
      // TODO: Sử dụng dịch vụ người dùng để lấy thông tin
      // Hiện tại đang hardcode một User mẫu
      final customer = User(
        id: customerId,
        email: 'customer@example.com',
        password: '',
        fullName: 'Khách hàng',
        phoneNumber: '0987654321',
        address: 'Địa chỉ khách hàng',
        role: UserRole.customer,
      );
      _customersCache[customerId] = customer;
      return customer;
    } catch (e) {
      print('Lỗi lấy thông tin khách hàng: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đơn hàng - ${widget.station.name}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.emptyImage,
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đơn hàng mới sẽ xuất hiện ở đây',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Sắp xếp đơn hàng theo thời gian và trạng thái
    _orders.sort((a, b) {
      if (a.status == 'pending' && b.status != 'pending') {
        return -1;
      }
      if (a.status != 'pending' && b.status == 'pending') {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return OrderCard(
            order: order,
            onTap: () => _viewOrderDetails(order),
            isOwner: true,
            onStatusChange: order.status == 'pending'
                ? (status) => _updateOrderStatus(order, status)
                : null,
          );
        },
      ),
    );
  }
}