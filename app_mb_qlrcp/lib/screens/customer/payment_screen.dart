import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../services/booking_service.dart';
import '../../services/customer_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import 'invoice_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Movie movie;
  final Showtime showtime;
  final int bookingId;
  final List<int> selectedSeatIds;
  final List<Map<String, dynamic>> foodItems;
  final double totalAmount;
  final double ticketTotal;
  final double foodTotal;

  const PaymentScreen({
    Key? key,
    required this.movie,
    required this.showtime,
    required this.bookingId,
    required this.selectedSeatIds,
    required this.foodItems,
    required this.totalAmount,
    required this.ticketTotal,
    required this.foodTotal,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ignore: unused_field
  final BookingService _bookingService = BookingService();
  final CustomerService _customerService = CustomerService();
  // ignore: unused_field
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _vnpayUrl;
  String? _errorMessage;
  // Promo state
  List<Map<String, dynamic>> _availablePromos = [];
  Map<String, dynamic>? _selectedPromo;
  String? _promoMessage;
  bool _promoApplied = false;
  late double _currentTotal;
  int _customerId = 0;
  // Payment confirmation state
  bool _isConfirming = false;
  String? _confirmingPromoCode;

  @override
  void initState() {
    super.initState();
    _currentTotal = widget.totalAmount;
    _loadQRCode();
    _loadAvailablePromos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAvailablePromos() async {
    try {
      final storage = StorageService();
      final user = await storage.getUser();
      _customerId = user?.userId ?? 0;

      if (_customerId <= 0) {
        print('⚠️ Không tìm thấy customer ID');
        return;
      }

      final resp = await _customerService.getAvailablePromoCodes(
        _customerId,
        widget.foodItems,
      );

      if (resp['success'] == true && resp['data'] is List) {
        setState(() {
          _availablePromos = List<Map<String, dynamic>>.from(
            resp['data'].cast<Map<String, dynamic>>(),
          );
          print('✅ Loaded ${_availablePromos.length} available promos');
        });
      }
    } catch (e) {
      print('❌ Error loading promos: $e');
    }
  }

  Future<void> _applySelectedPromo() async {
    if (_selectedPromo == null) {
      setState(() {
        _promoMessage = 'Vui lòng chọn mã khuyến mãi';
      });
      return;
    }

    final code = _selectedPromo!['maKhuyen'] as String? ?? '';
    if (code.isEmpty) {
      setState(() {
        _promoMessage = 'Mã khuyến mãi không hợp lệ';
      });
      return;
    }

    setState(() {
      _promoMessage = 'Đang áp dụng mã...';
    });

    try {
      final applyResp = await _customerService.applyPromoToBooking(
        widget.bookingId,
        code,
        originalTotal: widget.totalAmount,
      );

      if (applyResp['success'] == true && applyResp['data'] != null) {
        final applied = applyResp['data'];
        double? appliedTotal;
        if (applied is Map) {
          appliedTotal =
              (applied['final_total'] ??
                      applied['finalTotal'] ??
                      applied['total'] ??
                      applied['amount'])
                  is num
              ? (applied['final_total'] ??
                        applied['finalTotal'] ??
                        applied['total'] ??
                        applied['amount'])
                    .toDouble()
              : null;
        }

        setState(() {
          _promoApplied = true;
          _promoMessage =
              applyResp['message'] ?? 'Áp dụng mã khuyến mãi thành công';
          if (appliedTotal != null) _currentTotal = appliedTotal;
        });

        // Refresh QR code since total changed
        await _loadQRCode();
        return;
      }

      setState(() {
        _promoMessage =
            applyResp['message'] ?? 'Không thể áp dụng mã khuyến mãi';
        _promoApplied = false;
      });
    } catch (e) {
      setState(() {
        _promoMessage = 'Lỗi khi áp dụng mã: $e';
      });
    }
  }

  void _removePromo() {
    setState(() {
      _selectedPromo = null;
      _promoMessage = null;
      _promoApplied = false;
      _currentTotal = widget.totalAmount;
    });
  }

  Future<void> _confirmPayment() async {
    setState(() {
      _isConfirming = true;
      if (_promoApplied && _selectedPromo != null) {
        _confirmingPromoCode = _selectedPromo!['maKhuyen'] as String?;
      } else {
        _confirmingPromoCode = null;
      }
    });

    try {
      final confirmResp = await _customerService.confirmQRPayment(
        widget.bookingId,
        promoCode: _confirmingPromoCode,
      );

      if (confirmResp['success'] == true) {
        print('✅ Xác nhận thanh toán thành công, chờ Admin duyệt...');
        // Show waiting dialog
        if (mounted) {
          _showWaitingForApprovalDialog();
        }
        // Start polling for booking status
        await _pollBookingStatus();
      } else {
        setState(() {
          _isConfirming = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                confirmResp['message'] ?? 'Xác nhận thanh toán thất bại',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isConfirming = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pollBookingStatus() async {
    int pollCount = 0;
    const maxPolls = 60; // Poll for max 60 times (5 mins with 5s interval)
    const pollInterval = Duration(seconds: 5);

    while (pollCount < maxPolls && _isConfirming) {
      await Future.delayed(pollInterval);
      pollCount++;

      try {
        final bookingResp = await _customerService.getBookingDetail(
          widget.bookingId,
        );

        if (bookingResp['success'] == true && bookingResp['data'] != null) {
          final booking = bookingResp['data'];
          final status = booking['status'] as String? ?? '';

          print('📊 Poll $pollCount: Booking status = $status');

          if (status == 'Đã duyệt' ||
              status == 'Đã thanh toán' ||
              status == 'Đã Thanh toán') {
            setState(() {
              _isConfirming = false;
            });
            if (mounted) {
              Navigator.of(context).pop(); // Close waiting dialog
              _showPaymentSuccessWithInvoice(booking);
            }
            return;
          } else if (status == 'Đã hủy' || status == 'Bị từ chối') {
            setState(() {
              _isConfirming = false;
            });
            if (mounted) {
              Navigator.of(context).pop(); // Close waiting dialog
              _showPaymentFailedWithReason(booking);
            }
            return;
          }
          // Otherwise keep polling for "Chờ Duyệt"
        }
      } catch (e) {
        print('❌ Poll error: $e');
      }
    }

    // Timeout
    setState(() {
      _isConfirming = false;
    });
    if (mounted) {
      Navigator.of(context).pop(); // Close waiting dialog
      _showPaymentTimeout();
    }
  }

  void _showWaitingForApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⏳ Chờ Admin Duyệt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Đơn đặt vé của bạn đang chờ Admin duyệt...'),
              const SizedBox(height: 8),
              Text('Thời gian chờ tối đa: 5 phút', style: AppTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentSuccessWithInvoice(Map<String, dynamic> booking) {
    // Navigate to invoice screen instead of showing dialog
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => InvoiceScreen(booking: booking)),
      );
    }
  }

  void _showPaymentFailedWithReason(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('❌ Đơn hàng bị hủy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đơn đặt vé của bạn đã bị Admin hủy.'),
              const SizedBox(height: 12),
              Text('Lý do: ${booking['cancellation_reason'] ?? 'Không rõ'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to payment screen
              },
              child: const Text('Quay lại'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentTimeout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⏱️ Hết thời gian chờ'),
          content: const Text(
            'Admin chưa duyệt đơn trong thời gian quy định. Vui lòng kiểm tra trạng thái đơn hàng sau.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to payment screen
              },
              child: const Text('Quay lại'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadQRCode() async {
    try {
      setState(() => _isLoading = true);

      // Prefer CustomerService invoice QR endpoint (matches backend)
      final resp = await _customerService.getInvoiceQRCode(widget.bookingId);

      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        setState(() {
          _vnpayUrl =
              (data['qr_code_url'] ??
                      data['qrCodeUrl'] ??
                      data['qr_code'] ??
                      '')
                  .toString();
          _isLoading = false;
        });
        print('✅ QR Code loaded: ${_vnpayUrl}');
      } else {
        setState(() {
          _isLoading = false;
          final serverInfo = resp['server'];
          _errorMessage = resp['message'] ?? 'Lỗi lấy mã QR';
          if (serverInfo != null) {
            // Append server response for easier debugging
            _errorMessage = '$_errorMessage\nServer: ${serverInfo.toString()}';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  // ignore: unused_element
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

  // Use actual amounts from booking API
  double _getTicketTotal() {
    return widget.ticketTotal;
  }

  double _getFoodTotal() {
    return widget.foodTotal;
  }

  @override
  Widget build(BuildContext context) {
    final ticketTotal = _getTicketTotal();
    final foodTotal = _getFoodTotal();

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
                              _currentTotal,
                              isBold: true,
                              isLarge: true,
                              color: AppTheme.primaryOrange,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Promo code
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mã khuyến mãi', style: AppTheme.headingSmall),
                          const SizedBox(height: 8),
                          if (_availablePromos.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Không có mã khuyến mãi nào phù hợp',
                                  style: AppTheme.bodySmall,
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                // Dropdown to select promo
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<Map<String, dynamic>>(
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    hint: const Text('Chọn mã khuyến mãi'),
                                    value: _selectedPromo,
                                    onChanged: _promoApplied
                                        ? null
                                        : (Map<String, dynamic>? value) {
                                            setState(() {
                                              _selectedPromo = value;
                                              _promoMessage = null;
                                            });
                                          },
                                    items: _availablePromos.map((promo) {
                                      final isApplicable =
                                          promo['isApplicable'] == true;
                                      final moTa = promo['moTa'] ?? '';
                                      final reason = promo['reason'] ?? '';
                                      final displayText =
                                          '${promo['maKhuyen']} - ${isApplicable ? moTa : reason}';

                                      return DropdownMenuItem<
                                        Map<String, dynamic>
                                      >(
                                        value: promo,
                                        enabled: isApplicable,
                                        child: Text(
                                          displayText,
                                          style: TextStyle(
                                            color: isApplicable
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Show selected promo details
                                if (_selectedPromo != null &&
                                    _selectedPromo!['isApplicable'] == true)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF9E6),
                                      border: Border.all(
                                        color: const Color(0xFFFFD966),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedPromo!['moTa'] ?? '',
                                          style: AppTheme.bodySmall.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Giảm: ${_selectedPromo!['giaTriGiam']} ${_selectedPromo!['loaiGiam'] == '%' ? '%' : 'đ'}',
                                          style: AppTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                // Apply/Remove buttons
                                Row(
                                  children: [
                                    if (_selectedPromo != null &&
                                        _selectedPromo!['isApplicable'] ==
                                            true) ...[
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _promoApplied
                                              ? null
                                              : _applySelectedPromo,
                                          child: const Text('Áp dụng'),
                                        ),
                                      ),
                                    ] else if (_selectedPromo != null) ...[
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: null,
                                          child: Text(
                                            _selectedPromo!['reason'] ??
                                                'Không phù hợp',
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (_promoApplied) ...[
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _removePromo,
                                        icon: const Icon(Icons.close),
                                        label: const Text('Gỡ'),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          if (_promoMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _promoMessage!,
                              style: AppTheme.bodySmall.copyWith(
                                color: _promoApplied
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // QR Code Payment Section
                    if (_vnpayUrl != null && _vnpayUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quét Mã QR Để Thanh Toán',
                              style: AppTheme.headingSmall,
                            ),
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.error,
                                                    size: 48,
                                                    color: Colors.red,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    'Không thể tải mã QR',
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ElevatedButton(
                                                    onPressed: _loadQRCode,
                                                    child: const Text(
                                                      'Tải lại',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
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
                                      // children: [
                                      //   // Text(
                                      //   //   'Số tiền: ${widget.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} đ',
                                      //   //   style: AppTheme.bodySmall.copyWith(
                                      //   //     fontWeight: FontWeight.bold,
                                      //   //   ),
                                      //   // ),
                                      // ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _isConfirming
                                        ? null
                                        : _confirmPayment,
                                    icon: const Icon(Icons.check_circle),
                                    label: _isConfirming
                                        ? const Text('Đang xác nhận...')
                                        : const Text('Đã Thanh Toán'),
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
                          Text('Ghi Chú', style: AppTheme.headingSmall),
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
