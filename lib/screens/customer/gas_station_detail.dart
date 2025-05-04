// screens/customer/gas_station_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import 'package:xangdau_app/widget/custom_button.dart';

import '../../services/gas_station_service.dart';

import '../../models/gas_station.dart';
import '../../models/product.dart';
import 'order_screen.dart';
import 'rating_screen.dart';
import 'reviews_screen.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../../models/review.dart';

class GasStationDetailScreen extends StatefulWidget {
  final GasStation station;

  const GasStationDetailScreen({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  State<GasStationDetailScreen> createState() => _GasStationDetailScreenState();
}

class _GasStationDetailScreenState extends State<GasStationDetailScreen> {
  final GasStationService _stationService = GasStationService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;
  late ReviewService _reviewService;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();

    // Khởi tạo các service
    final authService = Provider.of<AuthService>(context, listen: false);
    _reviewService = ReviewService(authService: authService);

    // Tải dữ liệu
    _loadProducts();
    _loadReviews();
  }

  void _navigateToRatingScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RatingScreen(station: widget.station),
      ),
    );

    if (result == true) {
      _loadReviews(); // Tải lại đánh giá nếu đã thêm đánh giá mới
    }
  }

  void _navigateToReviewsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewsScreen(station: widget.station),
      ),
    );
  }

  Future<void> _loadReviews() async {
    try {
      final averageRating =
          await _reviewService.getStationAverageRating(widget.station.id);
      final reviews = await _reviewService.getStationReviews(widget.station.id);

      setState(() {
        _averageRating = averageRating;
        _reviewCount = reviews.length;
      });
    } catch (e) {
      print('Lỗi khi tải đánh giá: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products =
          await _stationService.getStationProducts(widget.station.id);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.generalError;
        _isLoading = false;
      });
      print('Lỗi khi tải sản phẩm: $e');
    }
  }

  Future<void> _makeOrder() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cửa hàng hiện không có sản phẩm nào'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderScreen(
          station: widget.station,
          products: _products.where((p) => p.status == 'available').toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildStationInfo(),
              _buildDivider(),
              _buildProductsList(),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // screens/customer/gas_station_detail.dart
// Cập nhật phần _buildAppBar()
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hiển thị ảnh trạm xăng
            widget.station.images.isNotEmpty
                ? PageView.builder(
                    itemCount: widget.station.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      try {
                        // Xử lý chuỗi base64
                        String imageData =
                            _cleanBase64String(widget.station.images[index]);

                        return Image.memory(
                          base64Decode(imageData),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Lỗi hiển thị ảnh: $error');
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.local_gas_station,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        );
                      } catch (e) {
                        print('Lỗi giải mã base64: $e');
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.local_gas_station,
                            size: 80,
                            color: Colors.grey,
                          ),
                        );
                      }
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.local_gas_station,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),

            // Gradient overlay cho chữ dễ đọc
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Chỉ báo ảnh
            if (widget.station.images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.station.images.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// Thêm hàm làm sạch chuỗi base64
  String _cleanBase64String(String base64String) {
    // Loại bỏ tiền tố nếu có
    String cleanString = base64String;
    if (base64String.contains('data:image')) {
      cleanString = base64String.split(',')[1];
    }

    // Loại bỏ khoảng trắng và xuống dòng
    cleanString = cleanString.trim().replaceAll('\n', '').replaceAll('\r', '');

    return cleanString;
  }

  Widget _buildStationInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.station.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.station.status == 'active'
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.station.status == 'active' ? 'Hoạt động' : 'Tạm ngừng',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.station.status == 'active'
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Địa chỉ
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: const Text('Địa chỉ'),
            subtitle: Text(
              '${widget.station.address}, ${widget.station.district}, ${widget.station.city}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                // Mở bản đồ (có thể triển khai sau)
              },
            ),
          ),

          // Số điện thoại
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.phone,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: const Text('Số điện thoại'),
            subtitle: Text(
              widget.station.phoneNumber,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: widget.station.phoneNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép số điện thoại'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),

          // Dịch vụ
          if (widget.station.services.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Dịch vụ cung cấp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.station.services.map((service) {
                return Chip(
                  label: Text(service),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primary),
                );
              }).toList(),
            ),
          ],

          // Mô tả
          if (widget.station.description != null &&
              widget.station.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Mô tả',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.station.description!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
          // Thêm ngay sau phần mô tả
// Đánh giá
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh giá',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _navigateToReviewsScreen,
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStarRating(_averageRating),
              const SizedBox(width: 8),
              Text(
                '${_averageRating.toStringAsFixed(1)} (${_reviewCount} đánh giá)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _navigateToRatingScreen,
                icon: const Icon(Icons.star),
                label: const Text('Đánh giá'),
              ),
            ],
          ),
        ],
      ),
    );
  }
Widget _buildStarRating(double rating) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      if (index < rating.floor()) {
        return const Icon(Icons.star, color: Colors.amber, size: 16);
      } else if (index < rating.ceil() && rating.floor() != rating.ceil()) {
        return const Icon(Icons.star_half, color: Colors.amber, size: 16);
      } else {
        return const Icon(Icons.star_border, color: Colors.amber, size: 16);
      }
    }),
  );
}
  Widget _buildDivider() {
    return Container(
      height: 8,
      color: Colors.grey[200],
    );
  }

  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Cửa hàng hiện chưa có sản phẩm nào',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final availableProducts =
        _products.where((p) => p.status == 'available').toList();
    final unavailableProducts =
        _products.where((p) => p.status != 'available').toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sản phẩm kinh doanh',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Sản phẩm có sẵn
          ...availableProducts.map((product) => _buildProductItem(product)),

          // Sản phẩm không có sẵn
          if (unavailableProducts.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Sản phẩm tạm hết',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...unavailableProducts.map((product) => _buildProductItem(product)),
          ],
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final isAvailable = product.status == 'available';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: product.type == 'xăng'
                ? AppColors.secondary.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            product.type == 'xăng' ? Icons.local_gas_station : Icons.opacity,
            color: product.type == 'xăng'
                ? AppColors.secondary
                : AppColors.primary,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.black : Colors.grey,
                ),
              ),
            ),
            if (!isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Tạm hết',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${product.price.toStringAsFixed(0)}đ/${product.unit}',
              style: TextStyle(
                color: isAvailable ? AppColors.primary : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.description.isNotEmpty)
              Text(
                product.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isAvailable ? Colors.black54 : Colors.grey,
                ),
              ),
          ],
        ),
        enabled: isAvailable,
      ),
    );
  }

  Widget _buildBottomBar() {
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
      child: CustomButton(
        text: 'Mua xăng dầu',
        onPressed: _makeOrder,
        isFullWidth: true,
        icon: Icons.shopping_cart,
        isDisabled: widget.station.status != 'active',
      ),
    );
  }
}
