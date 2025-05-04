// widgets/invoice_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order.dart';
import '../models/gas_station.dart';
import '../models/user.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';

class InvoiceWidget extends StatelessWidget {
  final Order order;
  final GasStation station;
  final User customer;

  const InvoiceWidget({
    Key? key,
    required this.order,
    required this.station,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printInvoice(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceHeader(),
              const SizedBox(height: 24),
              _buildCustomerInfo(),
              const SizedBox(height: 24),
              _buildProductTable(),
              const SizedBox(height: 24),
              _buildTotalSection(),
              const SizedBox(height: 32),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'HÓA ĐƠN BÁN HÀNG',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Mã hóa đơn: ${order.orderCode}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Ngày: ${DateFormat(AppConstants.dateTimeFormat).format(order.createdAt)}',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(thickness: 1),
        const SizedBox(height: 16),
        Text(
          'Cửa hàng: ${station.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Địa chỉ: ${station.address}, ${station.district}, ${station.city}',
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Điện thoại: ${station.phoneNumber}',
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin khách hàng:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tên: ${customer.fullName}',
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Điện thoại: ${customer.phoneNumber}',
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        if (customer.address.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Địa chỉ: ${customer.address}',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết sản phẩm:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Sản phẩm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Đơn giá',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Số lượng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Thành tiền',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              ...order.products.map((product) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(product.name),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${NumberFormat(AppConstants.currencyFormat).format(product.price)} ${AppConstants.currencySymbol}',
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${product.quantity.toStringAsFixed(2)} lít',
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${NumberFormat(AppConstants.currencyFormat).format(product.total)} ${AppConstants.currencySymbol}',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phương thức thanh toán:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                order.paymentMethod,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (order.earnedPoints > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Điểm tích lũy:',
                  style: TextStyle(fontSize: 14),
                ),
                Row(
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
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          'Cảm ơn quý khách đã sử dụng dịch vụ!',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Ngày ${DateFormat(AppConstants.dateFormat).format(DateTime.now())}',
          style: const TextStyle(
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontItalic = await PdfGoogleFonts.nunitoItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'HÓA ĐƠN BÁN HÀNG',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 20,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Mã hóa đơn: ${order.orderCode}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Ngày: ${DateFormat(AppConstants.dateTimeFormat).format(order.createdAt)}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 16),
              pw.Text(
                'Cửa hàng: ${station.name}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Địa chỉ: ${station.address}, ${station.district}, ${station.city}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Điện thoại: ${station.phoneNumber}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Thông tin khách hàng:',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Tên: ${customer.fullName}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Điện thoại: ${customer.phoneNumber}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                ),
              ),
              if (customer.address.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  'Địa chỉ: ${customer.address}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                  ),
                ),
              ],
              pw.SizedBox(height: 20),
              pw.Text(
                'Chi tiết sản phẩm:',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildPdfProductTable(font, fontBold),
              pw.SizedBox(height: 20),
              _buildPdfTotalSection(font, fontBold),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text(
                  'Cảm ơn quý khách đã sử dụng dịch vụ!',
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Ngày ${DateFormat(AppConstants.dateFormat).format(DateTime.now())}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfProductTable(pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Sản phẩm',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Đơn giá',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Số lượng',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Thành tiền',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        ...order.products.map(
          (product) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  product.name,
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${NumberFormat(AppConstants.currencyFormat).format(product.price)} ${AppConstants.currencySymbol}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${product.quantity.toStringAsFixed(2)} lít',
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${NumberFormat(AppConstants.currencyFormat).format(product.total)} ${AppConstants.currencySymbol}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTotalSection(pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Tổng tiền:',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
              pw.Text(
                '${NumberFormat(AppConstants.currencyFormat).format(order.totalAmount)} ${AppConstants.currencySymbol}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Phương thức thanh toán:',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.Text(
                order.paymentMethod,
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ],
          ),
          if (order.earnedPoints > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Điểm tích lũy:',
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                pw.Text(
                  '+${order.earnedPoints} điểm',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColors.amber,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}