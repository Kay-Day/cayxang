// services/gas_station_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:image_picker/image_picker.dart';
import '../models/gas_station.dart';
import '../models/product.dart';
import 'database_service.dart';

class GasStationService {
  final DatabaseService _db = DatabaseService();

  // Lấy tất cả trạm xăng
  Future<List<GasStation>> getAllStations() async {
    try {
      final stations = await _db.gasStationsCollection.find().toList();
      return stations.map((map) => GasStation.fromMap(map)).toList();
    } catch (e) {
      print('Lỗi khi lấy danh sách trạm xăng: $e');
      return [];
    }
  }

  // Lấy trạm xăng theo ID
  Future<GasStation?> getStationById(ObjectId id) async {
    try {
      final map = await _db.gasStationsCollection.findOne(where.id(id));
      if (map == null) return null;
      return GasStation.fromMap(map);
    } catch (e) {
      print('Lỗi khi lấy thông tin trạm xăng: $e');
      return null;
    }
  }

  // Lấy trạm xăng của chủ sở hữu
  Future<List<GasStation>> getOwnerStations(ObjectId ownerId) async {
    try {
      final stations = await _db.gasStationsCollection.find(where.eq('ownerId', ownerId)).toList();
      return stations.map((map) => GasStation.fromMap(map)).toList();
    } catch (e) {
      print('Lỗi khi lấy danh sách trạm xăng của chủ sở hữu: $e');
      return [];
    }
  }

  // Chuyển đổi hình ảnh từ file sang base64 (đã sửa)
  Future<String> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Tránh thêm tiền tố, chỉ trả về chuỗi base64 thuần túy
      return base64Encode(bytes);
    } catch (e) {
      print('Lỗi khi chuyển đổi hình ảnh sang base64: $e');
      return '';
    }
  }

  // Chọn ảnh từ thư viện ảnh (đã sửa)
  Future<String> pickAndConvertImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70, // Giảm chất lượng để giảm kích thước
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // Kiểm tra kích thước file
        final fileSize = await imageFile.length();
        if (fileSize > 1 * 1024 * 1024) { // 1MB
          print('Ảnh quá lớn: ${fileSize / 1024 / 1024}MB');
          return '';
        }
        
        return await convertImageToBase64(imageFile);
      }
      
      return '';
    } catch (e) {
      print('Lỗi khi chọn và chuyển đổi hình ảnh: $e');
      return '';
    }
  }

  // Thêm trạm xăng mới với hình ảnh
  Future<bool> addStation(GasStation station, List<String> base64Images) async {
    try {
      // Đảm bảo danh sách hình ảnh đã được làm sạch
      List<String> cleanedImages = base64Images.map((img) => cleanBase64String(img)).toList();
      
      // Đảm bảo trạm xăng có danh sách hình ảnh
      final stationWithImages = station.copyWith(
        images: cleanedImages.isEmpty ? [] : cleanedImages,
      );
      
      final result = await _db.gasStationsCollection.insertOne(stationWithImages.toMap());
      return result.isSuccess;
    } catch (e) {
      print('Lỗi khi thêm trạm xăng: $e');
      return false;
    }
  }

  // Cập nhật trạm xăng với hình ảnh (đã sửa)
  Future<bool> updateStation(GasStation station, List<String> newBase64Images) async {
    try {
      // Làm sạch danh sách hình ảnh mới
      List<String> cleanedNewImages = newBase64Images.map((img) => cleanBase64String(img)).toList();
      
      // Cập nhật danh sách hình ảnh
      List<String> updatedImages = station.images;
      
      if (cleanedNewImages.isNotEmpty) {
        updatedImages = [...station.images, ...cleanedNewImages];
      }
      
      final stationWithImages = station.copyWith(
        images: updatedImages,
      );
      
      final result = await _db.gasStationsCollection.updateOne(
        where.id(station.id),
        modify.set('name', station.name)
              .set('address', station.address)
              .set('district', station.district)
              .set('city', station.city)
              .set('phoneNumber', station.phoneNumber)
              .set('description', station.description)
              .set('services', station.services)
              .set('images', updatedImages)
              .set('status', station.status),
      );
      
      return result.isSuccess;
    } catch (e) {
      print('Lỗi khi cập nhật trạm xăng: $e');
      return false;
    }
  }

  // Làm sạch chuỗi base64 (thêm mới)
  String cleanBase64String(String base64String) {
    // Loại bỏ tiền tố nếu có
    String cleanString = base64String;
    if (base64String.contains('data:image')) {
      cleanString = base64String.split(',')[1];
    }
    
    // Loại bỏ khoảng trắng và xuống dòng
    cleanString = cleanString.trim().replaceAll('\n', '').replaceAll('\r', '');
    
    return cleanString;
  }

  // Xóa ảnh khỏi trạm xăng
  Future<bool> removeStationImage(ObjectId stationId, int imageIndex) async {
    try {
      final station = await getStationById(stationId);
      if (station == null) return false;
      
      List<String> updatedImages = List.from(station.images);
      if (imageIndex >= 0 && imageIndex < updatedImages.length) {
        updatedImages.removeAt(imageIndex);
        
        final result = await _db.gasStationsCollection.updateOne(
          where.id(stationId),
          modify.set('images', updatedImages),
        );
        
        return result.isSuccess;
      }
      
      return false;
    } catch (e) {
      print('Lỗi khi xóa ảnh trạm xăng: $e');
      return false;
    }
  }

  // Lấy danh sách sản phẩm của trạm xăng
  Future<List<Product>> getStationProducts(ObjectId stationId) async {
    try {
      final products = await _db.productsCollection.find(
        where.eq('stationId', stationId)
      ).toList();
      
      return products.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Lỗi khi lấy danh sách sản phẩm của trạm xăng: $e');
      return [];
    }
  }

  // Thêm phương thức tìm kiếm theo tên
  Future<List<GasStation>> searchStationsByName(String name) async {
    try {
      final searchRegex = RegExp(name, caseSensitive: false);
      final stations = await _db.gasStationsCollection.find(
        where.match('name', searchRegex.pattern)
      ).toList();
      
      return stations.map((map) => GasStation.fromMap(map)).toList();
    } catch (e) {
      print('Lỗi khi tìm kiếm trạm xăng theo tên: $e');
      return [];
    }
  }

  // Thêm phương thức tìm kiếm theo thành phố
  Future<List<GasStation>> searchStationsByCity(String city) async {
    try {
      final stations = await _db.gasStationsCollection.find(
        where.eq('city', city)
      ).toList();
      
      return stations.map((map) => GasStation.fromMap(map)).toList();
    } catch (e) {
      print('Lỗi khi tìm kiếm trạm xăng theo thành phố: $e');
      return [];
    }
  }
  // Thêm sản phẩm mới
Future<bool> addProduct(Product product) async {
  try {
    final result = await _db.productsCollection.insertOne(product.toMap());
    return result.isSuccess;
  } catch (e) {
    print('Lỗi khi thêm sản phẩm: $e');
    return false;
  }
}

// Cập nhật sản phẩm
Future<bool> updateProduct(Product product) async {
  try {
    final result = await _db.productsCollection.updateOne(
      where.id(product.id),
      modify.set('name', product.name)
            .set('type', product.type)
            .set('price', product.price)
            .set('unit', product.unit)
            .set('description', product.description)
            .set('status', product.status)
            .set('updatedAt', DateTime.now().toIso8601String()),
    );
    
    return result.isSuccess;
  } catch (e) {
    print('Lỗi khi cập nhật sản phẩm: $e');
    return false;
  }
}
}