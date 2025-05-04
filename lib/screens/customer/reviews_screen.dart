// screens/customer/reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import 'package:xangdau_app/widget/custom_button.dart';

import '../../models/gas_station.dart';
import '../../models/review.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';

import 'rating_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final GasStation station;

  const ReviewsScreen({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late ReviewService _reviewService;
  bool _isLoading = true;
  List<Review> _reviews = [];
  String? _errorMessage;
  double _averageRating = 0;
  
  @override
  void initState() {
    super.initState();
    
    final authService = Provider.of<AuthService>(context, listen: false);
    _reviewService = ReviewService(authService: authService);
    
    _loadReviews();
  }
  
  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Lấy danh sách đánh giá
      final reviews = await _reviewService.getStationReviews(widget.station.id);
      
      // Tính điểm đánh giá trung bình
      final averageRating = await _reviewService.getStationAverageRating(widget.station.id);
      
      setState(() {
        _reviews = reviews;
        _averageRating = averageRating;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.generalError;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _navigateToRatingScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RatingScreen(station: widget.station),
      ),
    );
    
    // Nếu đã đánh giá thành công, tải lại danh sách đánh giá
    if (result == true) {
      _loadReviews();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRatingScreen,
        child: const Icon(Icons.rate_review),
        tooltip: 'Thêm đánh giá',
      ),
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
              onPressed: _loadReviews,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        _buildStationInfo(),
        Expanded(
          child: _reviews.isEmpty
              ? _buildEmptyReviews()
              : _buildReviewsList(),
        ),
      ],
    );
  }
  
  Widget _buildStationInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStarRating(_averageRating),
                const SizedBox(width: 8),
                Text(
                  '${_averageRating.toStringAsFixed(1)} (${_reviews.length} đánh giá)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index < rating.ceil() && rating.floor() != rating.ceil()) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }
  
  Widget _buildEmptyReviews() {
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
            'Chưa có đánh giá nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy là người đầu tiên đánh giá trạm xăng này',
            style: TextStyle(
              color: AppColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Đánh giá ngay',
            onPressed: _navigateToRatingScreen,
            icon: Icons.rate_review,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewsList() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return _buildReviewItem(review);
        },
      ),
    );
  }
  
  Widget _buildReviewItem(Review review) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isCurrentUser = authService.currentUser?.id == review.customerId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        review.customerName.isNotEmpty
                            ? review.customerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(review.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isCurrentUser)
                  IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa đánh giá'),
                          content: const Text('Bạn có chắc chắn muốn xóa đánh giá này không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        // Xóa đánh giá
                        final success = await _reviewService.deleteReview(review.id);
                        if (success) {
                          _loadReviews(); // Tải lại danh sách sau khi xóa
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Xóa đánh giá',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStarRating(review.rating.toDouble()),
                const SizedBox(width: 8),
                Text(
                  '${review.rating}/5',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }
}