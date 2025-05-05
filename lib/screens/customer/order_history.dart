import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xangdau_app/models/order.dart';
import 'package:xangdau_app/services/auth_service.dart';
import 'package:xangdau_app/services/order_service.dart';
import 'package:xangdau_app/services/gas_station_service.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import 'package:xangdau_app/widget/order_card.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late OrderService _orderService;
  late GasStationService _stationService;
  bool _isLoading = true;
  List<Order> _orders = [];
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // Lấy AuthService từ Provider và truyền vào OrderService
    final authService = Provider.of<AuthService>(context, listen: false);
    _orderService = OrderService(authService: authService);
    _stationService = GasStationService();
    
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('Đang tải lịch sử đơn hàng...');
      final orders = await _orderService.getCustomerOrders();
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
      
      print('Đã tải ${orders.length} đơn hàng');
    } catch (e) {
      print('Lỗi khi tải lịch sử đơn hàng: $e');
      setState(() {
        _errorMessage = AppConstants.generalError;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
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
              style: const TextStyle(color: AppColors.error),
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
              'Bạn chưa thực hiện đơn hàng nào',
              style: TextStyle(
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          
          return OrderCard(
            order: order,
            onTap: () async {
              // Xử lý khi tap vào đơn hàng
              final station = await _stationService.getStationById(order.stationId);
              if (station != null) {
                // Hiển thị chi tiết đơn hàng hoặc hóa đơn
                // ...
              }
            },
          );
        },
      ),
    );
  }
}