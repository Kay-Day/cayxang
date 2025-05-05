import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

class Base64Image extends StatelessWidget {
  final String base64String;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const Base64Image({
    Key? key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (base64String.isEmpty) {
      return _buildErrorWidget();
    }
    
    try {
      // Làm sạch chuỗi base64
      final cleanedBase64 = ImageUtils.cleanBase64String(base64String);
      
      return Image.memory(
        base64Decode(cleanedBase64),
        width: width,
        height: height,
        fit: fit,
        // Lưu ý: Image.memory không có loadingBuilder
        // Thay thế bằng cách sử dụng FadeInImage hoặc đơn giản chỉ sử dụng Image.memory
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildPlaceholderWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          print('Lỗi hiển thị ảnh: $error');
          return _buildErrorWidget();
        },
      );
    } catch (e) {
      print('Lỗi khi giải mã base64: $e');
      return _buildErrorWidget();
    }
  }
  
  Widget _buildPlaceholderWidget() {
    return placeholder ?? Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return errorWidget ?? Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[600],
        size: (width ?? 100) * 0.5,
      ),
    );
  }
}