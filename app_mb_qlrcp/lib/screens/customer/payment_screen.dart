import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../services/booking_service.dart';
import '../../utils/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final Movie movie;
  final Showtime showtime;
  final int bookingId;
  final List<int> selectedSeatIds;
  final List<Map<String, dynamic>> foodItems;
  final double totalAmount;

  const PaymentScreen({
    Key? key,
    required this.movie,
    required this.showtime,
    required this.bookingId,
    required this.selectedSeatIds,
    required this.foodItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BookingService _bookingService = BookingService();
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _vnpayUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQRCode();
  }

  Future<void> _loadQRCode() async {
    try {
      setState(() => _isLoading = true);
      final result = await _bookingService.getQRCode(widget.bookingId);

      if (result['success'] == true) {
        setState(() {
          _vnpayUrl = result['qrCodeUrl'];
          _isLoading = false;
        });
        print('✅ QR Code loaded: ${_vnpayUrl}');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Lỗi lấy mã QR';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  void _handlePaymentCallback(String url) {
    // Handle payment success/failure
    if (url.contains('success') || url.contains('00')) {
      _showPaymentSuccess();
    } else {
      _showPaymentFailed();
    }
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('✅ Thanh toán thành công'),
          content: const Text('Đơn đặt vé của bạn đã được xác nhận'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // Go back to home
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentFailed() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('❌ Thanh toán thất bại'),
          content: const Text(
            'Thanh toán không thành công. Vui lòng thử lại hoặc chọn phương thức thanh toán khác.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to payment screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Calculate breakdown
  double _calculateTicketTotal() {
    // This would be passed from previous screen in real implementation
    return widget.totalAmount * 0.7; // Assume 70% is tickets
  }

  double _calculateFoodTotal() {
    double total = 0;
    for (var item in widget.foodItems) {
      final price = (item['price'] as num?) ?? 0;
      final quantity = (item['quantity'] as int?) ?? 0;
      total += price.toDouble() * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final ticketTotal = _calculateTicketTotal();
    final foodTotal = _calculateFoodTotal();

    return WillPopScope(
      onWillPop: () async {
        // Ask for confirmation before going back
        return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Quay lại?'),
                  content: const Text('Nếu quay lại, đơn đặt vé sẽ bị hủy.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Tiếp tục thanh toán'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Quay lại'),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh Toán'),
          backgroundColor: AppTheme.primaryOrange,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _errorMessage = null);
                        _loadQRCode();
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Movie Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.paleOrange,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movie.title,
                            style: AppTheme.headingSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.showtime.cinema} - ${widget.showtime.room}',
                            style: AppTheme.bodyMedium,
                          ),
                          Text(
                            '${widget.showtime.date} - ${widget.showtime.startTime}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    // Booking Summary
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thông Tin Đơn', style: AppTheme.headingSmall),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Ghế:',
                            'Ghế ${widget.selectedSeatIds.map((id) => id).join(", ")}',
                          ),
                          _buildSummaryRow(
                            'Số lượng vé:',
                            '${widget.selectedSeatIds.length}',
                          ),
                          if (widget.foodItems.isNotEmpty)
                            _buildSummaryRow(
                              'Đồ ăn:',
                              widget.foodItems
                                  .map((f) => '${f["name"]} x${f["quantity"]}')
                                  .join(', '),
                            ),
                        ],
                      ),
                    ),

                    // Price Breakdown
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.lightGray),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow('Tiền vé:', ticketTotal),
                            if (foodTotal > 0)
                              _buildPriceRow('Tiền đồ ăn:', foodTotal),
                            const Divider(height: 16),
                            _buildPriceRow(
                              'Tổng cộng:',
                              widget.totalAmount,
                              isBold: true,
                              isLarge: true,
                              color: AppTheme.primaryOrange,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // QR Code Payment Section
                    if (_vnpayUrl != null && _vnpayUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quét Mã QR Để Thanh Toán', style: AppTheme.headingSmall),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.lightGray),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  // QR Image
                                  Container(
                                    width: 300,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.network(
                                      _vnpayUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.error, size: 48, color: Colors.red),
                                              const SizedBox(height: 8),
                                              const Text('Không thể tải mã QR'),
                                              const SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: _loadQRCode,
                                                child: const Text('Tải lại'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Sử dụng ứng dụng ngân hàng để quét mã QR',
                                    style: AppTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.paleOrange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Số tiền: ${widget.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} đ',
                                          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showPaymentSuccess();
                                    },
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Đã Thanh Toán'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Payment Methods (kept for reference, QR is main now)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghi Chú',
                            style: AppTheme.headingSmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9E6),
                              border: Border.all(color: AppTheme.warning),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '📱 Mở ứng dụng ngân hàng hoặc Momo, VNPay, ZaloPay... để quét mã QR trên và hoàn tất thanh toán.\n\n✅ Sau khi thanh toán thành công, nhấn nút "Đã Thanh Toán" để xác nhận.',
                              style: AppTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isLarge = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isLarge
                ? TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )
                : TextStyle(
                    fontSize: 16,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
          ),
          Text(
            '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} đ',
            style: isLarge
                ? TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )
                : TextStyle(
                    fontSize: 16,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
          ),
        ],
      ),
    );
  }
}
