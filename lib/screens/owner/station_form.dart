// screens/owner/gas_station_form.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:provider/provider.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import 'package:xangdau_app/widget/custom_button.dart';

import '../../services/gas_station_service.dart';
import '../../services/auth_service.dart';

import '../../models/gas_station.dart';

class StationFormScreen extends StatefulWidget {
  final GasStation? station; // Null nếu tạo mới, có giá trị nếu cập nhật

  const StationFormScreen({
    Key? key,
    this.station,
  }) : super(key: key);

  @override
  State<StationFormScreen> createState() => _StationFormScreenState();
}

class _StationFormScreenState extends State<StationFormScreen> {
  final GasStationService _stationService = GasStationService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  List<String> _selectedServices = [];
  List<String> _base64Images = [];
  List<File> _imageFiles = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.station != null;
    
    if (_isEditing) {
      _nameController.text = widget.station!.name;
      _addressController.text = widget.station!.address;
      _districtController.text = widget.station!.district;
      _cityController.text = widget.station!.city;
      _phoneController.text = widget.station!.phoneNumber;
      _descriptionController.text = widget.station?.description ?? '';
      _selectedServices = List.from(widget.station!.services);
      _base64Images = List.from(widget.station!.images);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // screens/owner/gas_station_form.dart
// Cập nhật phương thức _pickImage
Future<void> _pickImage() async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ảnh quá lớn, vui lòng chọn ảnh nhỏ hơn 1MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      setState(() {
        _imageFiles.add(imageFile);
        _base64Images.add(base64Image);
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Cập nhật phần _buildImagesSection để hiển thị ảnh
Widget _buildImagesSection() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình ảnh cửa hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Hiển thị danh sách ảnh đã chọn
          if (_base64Images.isNotEmpty || _imageFiles.isNotEmpty)
            Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _base64Images.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: index < _imageFiles.length
                              ? Image.file(
                                  _imageFiles[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : _buildImageFromBase64(_base64Images[index]),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          // Nút thêm ảnh
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Thêm ảnh'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tối đa 5 ảnh, mỗi ảnh không quá 1MB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}

// Thêm phương thức xử lý hiển thị ảnh từ base64
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
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Lỗi hiển thị ảnh: $error');
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey[300],
          child: const Icon(
            Icons.error,
            color: Colors.red,
          ),
        );
      },
    );
  } catch (e) {
    print('Lỗi khi giải mã base64: $e');
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(
        Icons.error,
        color: Colors.red,
      ),
    );
  }
}
  

  void _removeImage(int index) {
    setState(() {
      if (index < _imageFiles.length) {
        _imageFiles.removeAt(index);
      }
      if (index < _base64Images.length) {
        _base64Images.removeAt(index);
      }
    });
  }

  Future<void> _saveGasStation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('Không thể xác định người dùng hiện tại');
      }

      final GasStation gasStation = GasStation(
        id: _isEditing ? widget.station!.id : null,
        ownerId: currentUser.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        district: _districtController.text.trim(),
        city: _cityController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        services: _selectedServices,
        images: _isEditing ? widget.station!.images : [],
        status: 'active',
      );

      bool success;
      if (_isEditing) {
        // Cập nhật trạm xăng hiện có
        success = await _stationService.updateStation(gasStation, _base64Images);
      } else {
        // Thêm trạm xăng mới
        success = await _stationService.addStation(gasStation, _base64Images);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? 'Cập nhật trạm xăng thành công'
                  : 'Thêm trạm xăng thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = _isEditing
              ? 'Không thể cập nhật trạm xăng. Vui lòng thử lại sau.'
              : 'Không thể thêm trạm xăng. Vui lòng thử lại sau.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
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
        title: Text(_isEditing ? 'Cập nhật trạm xăng' : 'Thêm trạm xăng mới'),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông tin cơ bản
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          
          // Hình ảnh
          _buildImagesSection(),
          const SizedBox(height: 24),
          
          // Dịch vụ cung cấp
          _buildServicesSection(),
          const SizedBox(height: 24),
          
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          
          // Nút lưu
          CustomButton(
            text: _isEditing ? 'Cập nhật trạm xăng' : 'Thêm trạm xăng',
            onPressed: _saveGasStation,
            isLoading: _isLoading,
            isFullWidth: true,
            icon: Icons.save,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên cửa hàng',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên cửa hàng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập địa chỉ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(
                      labelText: 'Quận/Huyện',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập quận/huyện';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Thành phố',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập thành phố';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (value.length < 10) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dịch vụ cung cấp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.gasStationServices.map((service) {
                final isSelected = _selectedServices.contains(service);
                return FilterChip(
                  label: Text(service),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}