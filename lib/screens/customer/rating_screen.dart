import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import 'package:xangdau_app/widget/custom_button.dart';

import '../../models/gas_station.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';

class RatingScreen extends StatefulWidget {
  final GasStation station;

  const RatingScreen({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  late ReviewService _reviewService;
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5; // Mặc định 5 sao
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    final authService = Provider.of<AuthService>(context, listen: false);
    _reviewService = ReviewService(authService: authService);
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _submitReview() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _reviewService.addReview(
        stationId: widget.station.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đánh giá thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Trả về true để biết đã đánh giá thành công
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đánh giá. Vui lòng thử lại sau.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
        title: const Text('Đánh giá trạm xăng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
            ),
            const SizedBox(height: 24),
            const Text(
              'Đánh giá của bạn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRatingSelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (không bắt buộc)',
                border: OutlineInputBorder(),
                hintText: 'Chia sẻ trải nghiệm của bạn tại trạm xăng này...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Gửi đánh giá',
              onPressed: _submitReview,
              isLoading: _isLoading,
              isFullWidth: true,
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: () {
            setState(() {
              _rating = starValue;
            });
          },
          icon: Icon(
            starValue <= _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 36,
          ),
          tooltip: '$starValue sao',
        );
      }),
    );
  }
}