import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import 'package:xangdau_app/widget/custom_button.dart';

import '../../services/gas_station_service.dart';
import '../../models/gas_station.dart';
import '../../models/product.dart';

class ProductManagementScreen extends StatefulWidget {
  final GasStation station;

  const ProductManagementScreen({
    Key? key,
    required this.station,
  }) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final GasStationService _stationService = GasStationService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _stationService.getStationProducts(widget.station.id);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.generalError;
        _isLoading = false;
      });
    }
  }

  void _showProductDialog({Product? product}) {
    final isEditing = product != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _typeController = TextEditingController();
    final _priceController = TextEditingController();
    final _unitController = TextEditingController();
    final _descriptionController = TextEditingController();
    String _status = 'available';

    if (isEditing) {
      _nameController.text = product.name;
      _typeController.text = product.type;
      _priceController.text = product.price.toString();
      _unitController.text = product.unit;
      _descriptionController.text = product.description;
      _status = product.status;
    } else {
      _unitController.text = 'lít';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Cập nhật sản phẩm' : 'Thêm sản phẩm mới'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên sản phẩm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _typeController.text.isEmpty ? 'xăng' : _typeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Loại',
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'xăng',
                      child: Text('Xăng'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'dầu',
                      child: Text('Dầu'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _typeController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn loại sản phẩm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá tiền',
                    suffixText: 'VNĐ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập giá tiền';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Giá tiền không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập đơn vị';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
               TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'available',
                      child: Text('Có sẵn'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'unavailable',
                      child: Text('Không có sẵn'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _status = value;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                _saveProduct(
                  isEditing,
                  product?.id,
                  _nameController.text.trim(),
                  _typeController.text,
                  double.parse(_priceController.text),
                  _unitController.text.trim(),
                  _descriptionController.text.trim(),
                  _status,
                );
              }
            },
            child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct(
    bool isEditing,
    mongo.ObjectId? id,
    String name,
    String type,
    double price,
    String unit,
    String description,
    String status,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isEditing && id != null) {
        // Cập nhật sản phẩm
        final updatedProduct = Product(
          id: id,
          stationId: widget.station.id,
          name: name,
          type: type,
          price: price,
          unit: unit,
          description: description,
          status: status,
        );

        final success = await _stationService.updateProduct(updatedProduct);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật sản phẩm thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadProducts();
        } else {
          setState(() {
            _errorMessage = 'Không thể cập nhật sản phẩm. Vui lòng thử lại sau.';
          });
        }
      } else {
        // Thêm sản phẩm mới
        final newProduct = Product(
          stationId: widget.station.id,
          name: name,
          type: type,
          price: price,
          unit: unit,
          description: description,
          status: status,
        );

        final success = await _stationService.addProduct(newProduct);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm sản phẩm thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadProducts();
        } else {
          setState(() {
            _errorMessage = 'Không thể thêm sản phẩm. Vui lòng thử lại sau.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.generalError;
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
        title: Text('Sản phẩm - ${widget.station.name}'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Thêm sản phẩm mới',
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
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
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
              'Chưa có sản phẩm nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thêm sản phẩm để bắt đầu bán hàng',
              style: TextStyle(
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Thêm sản phẩm',
              onPressed: () => _showProductDialog(),
              icon: Icons.add,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
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
                  product.type == 'xăng'
                      ? Icons.local_gas_station
                      : Icons.opacity,
                  color: product.type == 'xăng'
                      ? AppColors.secondary
                      : AppColors.primary,
                  size: 24,
                ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${NumberFormat(AppConstants.currencyFormat).format(product.price)}${AppConstants.currencySymbol}/${product.unit}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.description.isNotEmpty)
                    Text(
                      product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: product.status == 'available'
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  product.status == 'available' ? 'Có sẵn' : 'Hết hàng',
                  style: TextStyle(
                    fontSize: 12,
                    color: product.status == 'available'
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () => _showProductDialog(product: product),
            ),
          );
        },
      ),
    );
  }
}