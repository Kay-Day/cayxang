// services/review_service.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/review.dart';
import '../models/user.dart'; // Thêm import này
import 'database_service.dart';
import 'auth_service.dart';

class ReviewService {
  final DatabaseService _dbService = DatabaseService();
  late AuthService _authService;
  
  ReviewService({AuthService? authService}) {
    if (authService != null) {
      _authService = authService;
    } else {
      _authService = AuthService();
    }
  }
  
  // Thêm đánh giá mới
  Future<bool> addReview({
    required ObjectId stationId,
    required int rating,
    String comment = '',
  }) async {
    try {
      if (_authService.currentUser == null) {
        print('Không thể đánh giá: Người dùng chưa đăng nhập');
        return false;
      }
      
      // Kiểm tra xem người dùng đã đánh giá trạm này chưa
      final existingReview = await _dbService.reviewsCollection.findOne(
        where.eq('customerId', _authService.currentUser!.id)
            .eq('stationId', stationId)
      );
      
      if (existingReview != null) {
        // Nếu đã đánh giá rồi, cập nhật đánh giá cũ
        await _dbService.reviewsCollection.update(
          where.eq('_id', existingReview['_id']),
          {
            '\$set': {
              'rating': rating,
              'comment': comment,
              'createdAt': DateTime.now().toIso8601String(),
            }
          }
        );
        
        return true;
      }
      
      // Nếu chưa đánh giá, tạo đánh giá mới
      final review = Review(
        stationId: stationId,
        customerId: _authService.currentUser!.id,
        customerName: _authService.currentUser!.fullName,
        rating: rating,
        comment: comment,
      );
      
      await _dbService.reviewsCollection.insert(review.toMap());
      
      return true;
    } catch (e) {
      print('Lỗi khi thêm đánh giá: $e');
      return false;
    }
  }
  
  // Lấy đánh giá của một trạm
  Future<List<Review>> getStationReviews(ObjectId stationId) async {
    try {
      final reviews = await _dbService.reviewsCollection
          .find(where.eq('stationId', stationId))
          .toList();
      
      return reviews.map((review) => Review.fromMap(review)).toList();
    } catch (e) {
      print('Lỗi khi lấy đánh giá: $e');
      return [];
    }
  }
  
  // Lấy đánh giá trung bình của một trạm
  Future<double> getStationAverageRating(ObjectId stationId) async {
    try {
      final reviews = await getStationReviews(stationId);
      
      if (reviews.isEmpty) {
        return 0.0;
      }
      
      int totalRating = 0;
      for (var review in reviews) {
        totalRating += review.rating;
      }
      
      return totalRating / reviews.length;
    } catch (e) {
      print('Lỗi khi tính đánh giá trung bình: $e');
      return 0.0;
    }
  }
  
  // Xóa đánh giá
  Future<bool> deleteReview(ObjectId reviewId) async {
    try {
      if (_authService.currentUser == null) {
        return false;
      }
      
      // Chỉ người đánh giá hoặc người quản trị mới có thể xóa
      final review = await _dbService.reviewsCollection.findOne(
        where.eq('_id', reviewId)
      );
      
      if (review == null) {
        return false;
      }
      
      if (review['customerId'] != _authService.currentUser!.id && 
          _authService.currentUser!.role != 'owner') { // Sửa UserRole.owner thành 'owner'
        return false;
      }
      
      await _dbService.reviewsCollection.remove(where.eq('_id', reviewId));
      
      return true;
    } catch (e) {
      print('Lỗi khi xóa đánh giá: $e');
      return false;
    }
  }
}