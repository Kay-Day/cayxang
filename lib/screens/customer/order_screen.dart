// screens/customer/order_screen.dart
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import 'package:xangdau_app/widget/custom_button.dart';
import 'package:xangdau_app/widget/invoice_widget.dart';

import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/gas_station_service.dart';

import '../../models/gas_station.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../models/user.dart';

class OrderScreen extends StatefulWidget {
  final GasStation station;
  final List<Product> products;

  const OrderScreen({
    Key? key,
    required this.station,
    required this.products,
  }) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late OrderService _orderService;

  final Map<mongo.ObjectId, double> _quantities = {};
  String _selectedPaymentMethod = AppConstants.paymentMethods.first;
  bool _isLoading = false;
  String? _errorMessage;
  double _totalAmount = 0;
  int _earnedPoints = 0;
  bool _usePoints = false; // Có sử dụng điểm hay không
  int _availablePoints = 0; // Số điểm hiện có
  double _pointsDiscount = 0; // Giá trị giảm giá từ điểm

  @override
  void initState() {
    super.initState();
    // Khởi tạo số lượng mặc định
    for (var product in widget.products) {
      _quantities[product.id] = 0;
    }

    // Lấy AuthService từ Provider và truyền vào OrderService
    final authService = Provider.of<AuthService>(context, listen: false);
    _orderService = OrderService(authService: authService);

    // Lấy số điểm hiện có của người dùng
    if (authService.currentUser != null) {
      _availablePoints = authService.currentUser!.points;
    }
  }

// Thêm phương thức tính giảm giá từ điểm
  void _calculatePointsDiscount() {
    if (_usePoints && _availablePoints > 0) {
      // Quy đổi: 5 điểm = 5.000 VND
      final pointValue = 1000.0; // 1 điểm = 1.000 VND

      // Tính toán số điểm tối đa có thể sử dụng
      // Không thể giảm giá nhiều hơn tổng tiền đơn hàng
      final maxPointsToUse = (_totalAmount / pointValue).floor();
      final pointsToUse =
          _availablePoints > maxPointsToUse ? maxPointsToUse : _availablePoints;

      setState(() {
        _pointsDiscount = pointsToUse * pointValue;
      });
    } else {
      setState(() {
        _pointsDiscount = 0;
      });
    }
  }

  void _updateQuantity(Product product, double newValue) {
    setState(() {
      _quantities[product.id] = newValue;
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0;
    for (var product in widget.products) {
      total += product.price * (_quantities[product.id] ?? 0);
    }

    setState(() {
      _totalAmount = total;

      // Tính điểm thưởng mới dựa trên tổng tiền chưa giảm giá
      _earnedPoints = total >= AppConstants.pointsThreshold
          ? ((total / AppConstants.pointsThreshold) * AppConstants.pointsRate)
              .floor()
          : 0;

      // Tính lại giảm giá từ điểm
      _calculatePointsDiscount();
    });
  }

  Future<void> _createOrder() async {
    // Kiểm tra xem đã chọn sản phẩm nào chưa
    bool hasSelectedProduct = false;
    for (var quantity in _quantities.values) {
      if (quantity > 0) {
        hasSelectedProduct = true;
        break;
      }
    }

    if (!hasSelectedProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một sản phẩm'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tạo danh sách sản phẩm đã chọn
      final List<OrderItem> selectedProducts = [];
      for (var product in widget.products) {
        final quantity = _quantities[product.id] ?? 0;
        if (quantity > 0) {
          selectedProducts.add(
            OrderItem(
              productId: product.id,
              name: product.name,
              price: product.price,
              quantity: quantity,
              total: product.price * quantity,
            ),
          );
        }
      }

      // Tính tổng tiền sau giảm giá
      final finalAmount = _totalAmount - _pointsDiscount;

      // Số điểm sẽ sử dụng
      final pointsToUse = _usePoints ? (_pointsDiscount / 1000).floor() : 0;

      // Tạo đơn hàng với thông tin giảm giá
      final order = await _orderService.createOrder(
        stationId: widget.station.id,
        products: selectedProducts,
        totalAmount: finalAmount, // Tổng tiền sau giảm giá
        paymentMethod: _selectedPaymentMethod,
        usedPoints: pointsToUse, // Thêm số điểm đã sử dụng
        discount: _pointsDiscount, // Thêm số tiền giảm giá
      );

      if (order != null) {
        // Lấy thông tin người dùng hiện tại
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        // Hiển thị hóa đơn
        if (currentUser != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => InvoiceWidget(
                order: order,
                station: widget.station,
                customer: currentUser,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Không thể tạo đơn hàng. Vui lòng thử lại sau.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.generalError;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mua xăng dầu'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStationInfo(),
                const SizedBox(height: 16),
                _buildProductsList(),
                const SizedBox(height: 24),
                _buildPaymentMethod(),
                const SizedBox(height: 16),
                _buildPointsUse(), // Thêm phần sử dụng điểm vào đây
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // Thêm vào OrderScreen sau phần _buildPaymentMethod
  Widget _buildPointsUse() {
    if (_availablePoints <= 0) {
      return const SizedBox.shrink(); // Không hiển thị nếu không có điểm
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sử dụng điểm tích lũy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Bạn có $_availablePoints điểm (${NumberFormat(AppConstants.currencyFormat).format(_availablePoints * 1000)} ${AppConstants.currencySymbol})',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: _usePoints,
                  onChanged: (value) {
                    setState(() {
                      _usePoints = value;
                      _calculatePointsDiscount();
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sử dụng điểm để giảm giá đơn hàng',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (_usePoints && _pointsDiscount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Giảm giá: -${NumberFormat(AppConstants.currencyFormat).format(_pointsDiscount)} ${AppConstants.currencySymbol}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.station.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${widget.station.address}, ${widget.station.district}, ${widget.station.city}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn sản phẩm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.products.map((product) => _buildProductItem(product)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: product.type == 'xăng'
                  ? AppColors.secondary.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              product.type == 'xăng' ? Icons.local_gas_station : Icons.opacity,
              color: product.type == 'xăng'
                  ? AppColors.secondary
                  : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat(AppConstants.currencyFormat).format(product.price)}${AppConstants.currencySymbol}/${product.unit}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Số lượng (lít)',
                suffix: Text(product.unit),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                double? newValue = double.tryParse(value);
                if (newValue != null && newValue >= 0) {
                  _updateQuantity(product, newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: AppConstants.paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    // Tính tổng tiền sau giảm giá
    final finalAmount = _totalAmount - _pointsDiscount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạm tính:',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                '${NumberFormat(AppConstants.currencyFormat).format(_totalAmount)} ${AppConstants.currencySymbol}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (_pointsDiscount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giảm giá từ điểm:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  '-${NumberFormat(AppConstants.currencyFormat).format(_pointsDiscount)} ${AppConstants.currencySymbol}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${NumberFormat(AppConstants.currencyFormat).format(finalAmount)} ${AppConstants.currencySymbol}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (_earnedPoints > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Bạn sẽ nhận được $_earnedPoints điểm',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          CustomButton(
            text: 'Xác nhận đơn hàng',
            onPressed: _createOrder,
            isLoading: _isLoading,
            isFullWidth: true,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }
}
