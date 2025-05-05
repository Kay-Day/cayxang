import 'dart:convert';
import 'dart:typed_data';

class ImageUtils {
  /// Kiểm tra chuỗi base64 có hợp lệ không
  static bool isValidBase64(String base64String) {
    try {
      // Loại bỏ tiền tố nếu có
      String cleanedBase64 = base64String;
      if (base64String.contains('data:image')) {
        cleanedBase64 = base64String.split(',')[1];
      }
      
      // Loại bỏ khoảng trắng và xuống dòng
      cleanedBase64 = cleanedBase64.trim().replaceAll('\n', '').replaceAll('\r', '');
      
      // Thử decode chuỗi base64
      base64Decode(cleanedBase64);
      return true;
    } catch (e) {
      print('Chuỗi base64 không hợp lệ: $e');
      return false;
    }
  }

  /// Làm sạch chuỗi base64
  static String cleanBase64String(String base64String) {
    // Loại bỏ tiền tố nếu có
    String cleanedBase64 = base64String;
    if (base64String.contains('data:image')) {
      cleanedBase64 = base64String.split(',')[1];
    }
    
    // Loại bỏ khoảng trắng và xuống dòng
    cleanedBase64 = cleanedBase64.trim().replaceAll('\n', '').replaceAll('\r', '');
    
    return cleanedBase64;
  }

  /// Nén ảnh base64 để giảm kích thước
  static Future<String> compressBase64Image(String base64String, {int quality = 70}) async {
    try {
      // Không xử lý nếu chuỗi không hợp lệ
      if (!isValidBase64(base64String)) {
        return base64String;
      }
      
      String cleanedBase64 = cleanBase64String(base64String);
      
      // Decode chuỗi base64 thành Uint8List
      Uint8List bytes = base64Decode(cleanedBase64);
      
      // Nếu có thư viện để nén ảnh (như flutter_image_compress), bạn có thể thêm vào đây
      // Ví dụ: bytes = await FlutterImageCompress.compressWithList(bytes, quality: quality);
      
      // Mã hóa trở lại thành chuỗi base64
      return base64Encode(bytes);
    } catch (e) {
      print('Lỗi khi nén ảnh base64: $e');
      return base64String;
    }
  }

  /// Tạo thumbnail từ chuỗi base64
  static Future<String> createThumbnailFromBase64(String base64String, {int maxWidth = 100, int maxHeight = 100}) async {
    try {
      // Không xử lý nếu chuỗi không hợp lệ
      if (!isValidBase64(base64String)) {
        return base64String;
      }
      
      String cleanedBase64 = cleanBase64String(base64String);
      
      // Decode chuỗi base64 thành Uint8List
      Uint8List bytes = base64Decode(cleanedBase64);
      
      // Nếu có thư viện để resize ảnh, bạn có thể thêm vào đây
      // Ví dụ: bytes = await ImageResize.resize(bytes, width: maxWidth, height: maxHeight);
      
      // Mã hóa trở lại thành chuỗi base64
      return base64Encode(bytes);
    } catch (e) {
      print('Lỗi khi tạo thumbnail từ ảnh base64: $e');
      return base64String;
    }
  }
}