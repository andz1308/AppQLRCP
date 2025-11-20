import 'package:flutter/material.dart';
import '../../services/invoice_service.dart';
import '../../utils/app_theme.dart';

class InvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const InvoiceScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _isGeneratingPDF = false;

  Future<void> _generateAndSavePDF() async {
    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      await InvoiceService.generateAndSaveInvoicePDF(widget.booking);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Hóa đơn đã được lưu'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPDF = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.booking['booking_id']?.toString() ?? 'N/A';
    final customerName = widget.booking['customer_name']?.toString() ?? 'N/A';
    final customerEmail = widget.booking['customer_email']?.toString() ?? 'N/A';
    final customerPhone = widget.booking['customer_phone']?.toString() ?? 'N/A';
    final createdAt = widget.booking['created_at']?.toString() ?? 'N/A';
    final totalAmount = widget.booking['total_amount']?.toString() ?? '0';
    final movieTitle = widget.booking['movie']?['title']?.toString() ?? 'N/A';
    final cinema = widget.booking['showtime']?['cinema']?.toString() ?? 'N/A';
    final room = widget.booking['showtime']?['room']?.toString() ?? 'N/A';
    final date = widget.booking['showtime']?['date']?.toString() ?? 'N/A';
    final time = widget.booking['showtime']?['time']?.toString() ?? 'N/A';
    final tickets = widget.booking['tickets'] as List? ?? [];

    return WillPopScope(
      onWillPop: () async {
        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hóa Đơn'),
          backgroundColor: AppTheme.primaryOrange,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Text(
                      'HÓA ĐƠN THANH TOÁN',
                      style: AppTheme.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('ĐƠNG ĐẶT VÉ XEM PHIM', style: AppTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Booking info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightGray),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Mã đơn:', bookingId),
                    _buildInfoRow('Ngày đặt:', createdAt),
                    _buildInfoRow(
                      'Trạng thái:',
                      widget.booking['status'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer info
              Text('Thông Tin Khách Hàng', style: AppTheme.headingSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightGray),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Tên:', customerName),
                    _buildInfoRow('Email:', customerEmail),
                    _buildInfoRow('Điện thoại:', customerPhone),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Showtime info
              Text('Thông Tin Suất Chiếu', style: AppTheme.headingSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.lightGray),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Phim:', movieTitle),
                    _buildInfoRow('Rạp:', cinema),
                    _buildInfoRow('Phòng:', room),
                    _buildInfoRow('Ngày chiếu:', date),
                    _buildInfoRow('Giờ chiếu:', time),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tickets
              Text('Chi Tiết Vé', style: AppTheme.headingSmall),
              const SizedBox(height: 8),
              ...tickets.asMap().entries.map((entry) {
                final idx = entry.key;
                final ticket = entry.value as Map<String, dynamic>;
                final seatNumber = ticket['seat_number']?.toString() ?? 'N/A';
                final qrCode = ticket['qr_code']?.toString() ?? 'N/A';
                final price = ticket['price']?.toString() ?? '0';
                final status = ticket['status']?.toString() ?? 'N/A';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.paleOrange),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFFFF9E6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vé #${idx + 1}',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Ghế:', seatNumber),
                        _buildInfoRow('Mã vé:', qrCode),
                        _buildInfoRow('Giá:', '$price đ'),
                        _buildInfoRow('Trạng thái:', status),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.paleOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng cộng:', style: AppTheme.headingSmall),
                    Text(
                      '$totalAmount đ',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              ElevatedButton.icon(
                onPressed: _isGeneratingPDF ? null : _generateAndSavePDF,
                icon: const Icon(Icons.save_alt),
                label: _isGeneratingPDF
                    ? const Text('Đang lưu...')
                    : const Text('Lưu PDF'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Về Trang Chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
