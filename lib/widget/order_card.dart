// widgets/order_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final bool isOwner;
  final Function(String)? onStatusChange;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onTap,
    this.isOwner = false,
    this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mã đơn: ${order.orderCode}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusWidget(),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildProductsList(),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${NumberFormat(AppConstants.currencyFormat).format(order.totalAmount)} ${AppConstants.currencySymbol}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (order.earnedPoints > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${order.earnedPoints} điểm',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              _buildFooterWidget(context),
              if (isOwner && order.status == 'pending')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildOwnerActions(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    Color statusColor;
    String statusText = AppConstants.orderStatus[order.status] ?? 'Không xác định';

    switch (order.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.lightText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...order.products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_gas_station,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${product.quantity.toStringAsFixed(2)} lít x ${NumberFormat(AppConstants.currencyFormat).format(product.price)} ${AppConstants.currencySymbol}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildFooterWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppColors.lightText,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat(AppConstants.dateTimeFormat).format(order.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(
              Icons.payment,
              size: 14,
              color: AppColors.lightText,
            ),
            const SizedBox(width: 4),
            Text(
              order.paymentMethod,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () {
            if (onStatusChange != null) {
              onStatusChange!('completed');
            }
          },
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.success,
          ),
          label: const Text(
            'Hoàn thành',
            style: TextStyle(color: AppColors.success),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            if (onStatusChange != null) {
              onStatusChange!('cancelled');
            }
          },
          icon: const Icon(
            Icons.cancel,
            color: AppColors.error,
          ),
          label: const Text(
            'Hủy đơn',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}