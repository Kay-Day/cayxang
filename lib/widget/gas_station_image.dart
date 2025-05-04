// widgets/gas_station_image.dart
import 'dart:convert';
import 'package:flutter/material.dart';

class GasStationImage extends StatelessWidget {
  final List<String> images;
  final double width;
  final double height;
  final BoxFit fit;
  
  const GasStationImage({
    Key? key,
    required this.images,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return _buildDefaultImage();
    }
    
    try {
      // Lấy ảnh đầu tiên từ danh sách và làm sạch
      String cleanedBase64 = _cleanBase64String(images.first);
      
      return Image.memory(
        base64Decode(cleanedBase64),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print('Lỗi hiển thị ảnh: $error');
          return _buildDefaultImage();
        },
      );
    } catch (e) {
      print('Lỗi khi giải mã base64: $e');
      return _buildDefaultImage();
    }
  }
  
  // Hàm làm sạch chuỗi base64
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
  
  Widget _buildDefaultImage() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.local_gas_station,
        color: Colors.grey[600],
        size: width * 0.5,
      ),
    );
  }
}