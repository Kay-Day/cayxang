// widgets/gas_station_card.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/gas_station.dart';
import '../../services/config/themes.dart';

class GasStationCard extends StatelessWidget {
  final GasStation station;
  final VoidCallback onTap;

  const GasStationCard({
    Key? key,
    required this.station,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh trạm xăng
            SizedBox(
              height: 150,
              width: double.infinity,
              child: station.images.isNotEmpty
                  ? _buildImageFromBase64(station.images.first)
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.local_gas_station,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          station.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: station.status == 'active'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          station.status == 'active' ? 'Hoạt động' : 'Tạm ngừng',
                          style: TextStyle(
                            fontSize: 12,
                            color: station.status == 'active'
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                          '${station.address}, ${station.district}, ${station.city}',
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        station.phoneNumber,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (station.services.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: station.services.map((service) {
                        return Chip(
                          label: Text(service),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm xử lý hiển thị ảnh từ base64 (đã sửa)
  Widget _buildImageFromBase64(String base64String) {
    try {
      // Xử lý chuỗi base64
      String cleanedBase64 = base64String;
      if (base64String.contains('data:image')) {
        cleanedBase64 = base64String.split(',')[1];
      }
      
      // Loại bỏ khoảng trắng và xuống dòng
      cleanedBase64 = cleanedBase64.trim().replaceAll('\n', '').replaceAll('\r', '');
      
      return Image.memory(
        base64Decode(cleanedBase64),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 150,
        errorBuilder: (context, error, stackTrace) {
          print('Lỗi hiển thị ảnh: $error');
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.local_gas_station,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      );
    } catch (e) {
      print('Lỗi khi giải mã base64: $e');
      return Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.local_gas_station,
          size: 50,
          color: Colors.grey,
        ),
      );
    }
  }
}