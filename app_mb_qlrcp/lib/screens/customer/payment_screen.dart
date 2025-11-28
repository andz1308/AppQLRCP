import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
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
  final CustomerService _customerService = CustomerService();

  // Promo state
  List<Map<String, dynamic>> _availablePromos = [];
  Map<String, dynamic>? _selectedPromo;
  String? _promoMessage;
  bool _promoApplied = false;
  late double _currentTotal;
  int _customerId = 0;

  // Payment confirmation state
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _currentTotal = widget.totalAmount;
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

      print('🔍 Loading promos for customer: $_customerId');
      final resp = await _customerService.getAvailablePromoCodes(
        _customerId,
        widget.foodItems,
      );
      print(
        '🔍 Promo response: success=${resp['success']}, data_type=${resp['data'].runtimeType}, data_length=${(resp['data'] as List?)?.length ?? 0}',
      );
      print('🔍 Full response data: ${resp['data']}');

      if (resp['success'] == true && resp['data'] is List) {
        setState(() {
          var promos = List<Map<String, dynamic>>.from(
            resp['data'].cast<Map<String, dynamic>>(),
          );

          // Sort: Applicable first
          promos.sort((a, b) {
            bool aApp = a['isApplicable'] == true;
            bool bApp = b['isApplicable'] == true;
            if (aApp && !bApp) return -1;
            if (!aApp && bApp) return 1;
            return 0;
          });

          _availablePromos = promos;
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

    // ✅ KIỂM TRA XEM MÃ CÓ ĐƯỢC PHÉP ÁP DỤNG KHÔNG
    final isApplicable = _selectedPromo!['isApplicable'] == true;
    if (!isApplicable) {
      final reason = _selectedPromo!['reason'] as String? ?? '';
      setState(() {
        _promoMessage = 'Mã này không thể áp dụng: $reason';
      });
      return;
    }

    final code = _selectedPromo!['ma_khuyen_mai'] as String? ?? '';
    if (code.isEmpty) {
      setState(() {
        _promoMessage = 'Mã khuyến mãi không hợp lệ';
      });
      return;
    }

    setState(() {
      _promoMessage = 'Đang áp dụng mã...';
    });

    print(
      '🔍 Applying promo: code=$code, bookingId=${widget.bookingId}, totalAmount=${widget.totalAmount}',
    );

    try {
      final applyResp = await _customerService.applyPromoToBooking(
        widget.bookingId,
        code,
        originalTotal: widget.totalAmount,
      );
      print('🔍 Promo apply response: $applyResp');

      if (applyResp['success'] == true && applyResp['data'] != null) {
        final applied = applyResp['data'];
        double? appliedTotal;

        if (applied is Map) {
          // API returns: final_total, original_total, discount_amount, etc.
          final finalTotal = applied['final_total'];
          print(
            '🔍 Final total from API: $finalTotal (type: ${finalTotal.runtimeType})',
          );

          if (finalTotal is num) {
            appliedTotal = finalTotal.toDouble();
          }
        }

        print('✅ Promo applied! New total: $appliedTotal');

        setState(() {
          _promoApplied = true;
          _promoMessage =
              applyResp['message'] ?? 'Áp dụng mã khuyến mãi thành công';
          if (appliedTotal != null && appliedTotal > 0) {
            _currentTotal = appliedTotal;
            print('✅ Updated _currentTotal to: $_currentTotal');
          }
        });
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
          title: const Text('Thanh Toán VNPay'),
          backgroundColor: AppTheme.primaryOrange,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
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
                    Text(widget.movie.title, style: AppTheme.headingSmall),
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
                      _buildPriceRow('Tiền vé:', widget.ticketTotal),
                      if (widget.foodTotal > 0)
                        _buildPriceRow('Tiền đồ ăn:', widget.foodTotal),
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

              // Promo code section
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              items: _availablePromos
                                  .where(
                                    (promo) => promo['isApplicable'] == true,
                                  )
                                  .map((promo) {
                                    // API now returns all promos with isApplicable flag
                                    final isApplicable =
                                        promo['isApplicable'] == true;
                                    final reason = promo['reason'] ?? '';
                                    final moTa = promo['mo_ta'] ?? '';
                                    final maKhuyen =
                                        promo['ma_khuyen_mai'] ?? '';

                                    String displayText = '$maKhuyen - $moTa';
                                    if (!isApplicable && reason.isNotEmpty) {
                                      displayText += ' ($reason)';
                                    }

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
                                          decoration: isApplicable
                                              ? null
                                              : TextDecoration.lineThrough,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_promoMessage != null)
                            Text(
                              _promoMessage!,
                              style: AppTheme.bodySmall.copyWith(
                                color: _promoApplied
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_selectedPromo != null) ...[
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _promoApplied
                                        ? null
                                        : _applySelectedPromo,
                                    child: const Text('Áp dụng'),
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
                  ],
                ),
              ),

              // VNPay Payment Instructions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phương Thức Thanh Toán',
                      style: AppTheme.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.paleOrange,
                        border: Border.all(color: AppTheme.primaryOrange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payment,
                                color: AppTheme.primaryOrange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Thanh Toán VNPay',
                                style: AppTheme.headingSmall.copyWith(
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '✓ Thanh toán nhanh chóng qua VNPay\n'
                            '✓ An toàn với các phương thức thanh toán khác nhau\n'
                            '✓ Nhận email xác nhận ngay sau khi thanh toán thành công\n'
                            '✓ Email hóa đơn sẽ được gửi tự động',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Payment Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isConfirming ? null : _confirmPayment,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    _isConfirming ? 'Đang xử lý...' : 'Thanh Toán Ngay',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Xử lý thanh toán VNPay
  Future<void> _confirmPayment() async {
    setState(() => _isConfirming = true);

    try {
      // Bước 1: Lấy VNPay payment URL từ API
      print('📲 Bước 1: Lấy VNPay payment URL...');
      final urlResp = await _customerService.getVNPayPaymentUrl(
        widget.bookingId,
      );

      if (urlResp['success'] != true) {
        print('❌ Lấy VNPay URL thất bại: ${urlResp['message']}');
        if (mounted) {
          _showPaymentFailed(
            urlResp['message'] ?? 'Không thể lấy URL thanh toán',
          );
        }
        setState(() => _isConfirming = false);
        return;
      }

      final paymentData = urlResp['data'] as Map<String, dynamic>?;
      if (paymentData == null) {
        print('❌ Dữ liệu thanh toán trống');
        if (mounted) {
          _showPaymentFailed('Dữ liệu thanh toán không hợp lệ');
        }
        setState(() => _isConfirming = false);
        return;
      }

      final paymentUrl = paymentData['payment_url'] as String?;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        print('❌ URL thanh toán trống');
        if (mounted) {
          _showPaymentFailed('URL thanh toán không hợp lệ');
        }
        setState(() => _isConfirming = false);
        return;
      }

      print('✅ Bước 1: Đã lấy VNPay URL');

      // Bước 2: Mở WebView để user thanh toán
      print('📲 Bước 2: Mở WebView VNPay...');
      if (mounted) {
        setState(() => _isConfirming = false);
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => VNPayWebView(
              paymentUrl: paymentUrl,
              bookingId: widget.bookingId,
              onPaymentComplete: _handleVNPayCallback,
            ),
          ),
        );

        if (result != null && result['success'] == true) {
          if (mounted) _showPaymentSuccess();
        } else if (result != null && result['success'] == false) {
          if (mounted) _showPaymentFailed(result['message']);
        } else {
          if (mounted) {
            print('❌ Thanh toán bị hủy');
            _showPaymentFailed('Thanh toán bị hủy bởi người dùng');
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi xử lý thanh toán: $e');
      if (mounted) {
        _showPaymentFailed(e.toString());
      }
      setState(() => _isConfirming = false);
    }
  }

  /// Xử lý callback khi VNPay thanh toán thành công
  Future<Map<String, dynamic>> _handleVNPayCallback({
    required String responseCode,
    String? transactionNo,
  }) async {
    print('📲 Bước 3: Xử lý callback từ VNPay...');
    print('Response Code: $responseCode, TransactionNo: $transactionNo');

    setState(() => _isConfirming = true);

    try {
      // Gọi API process-vnpay-payment để xác thực thanh toán
      final vnpayResp = await _customerService.processVNPayPayment(
        bookingId: widget.bookingId,
        responseCode: responseCode,
        transactionNo: transactionNo ?? '',
      );

      if (vnpayResp['success'] == true) {
        print('✅ Bước 3: Thanh toán VNPay thành công');
        return {'success': true};
      } else {
        print('❌ Bước 3: Thanh toán VNPay thất bại: ${vnpayResp['message']}');
        return {
          'success': false,
          'message': vnpayResp['message'] ?? 'Lỗi không xác định',
        };
      }
    } catch (e) {
      print('❌ Bước 3: Lỗi xử lý callback: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      setState(() => _isConfirming = false);
    }
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('✅ Thanh toán thành công'),
          content: const Text(
            'Đơn đặt vé của bạn đã được xác nhận và email xác nhận đã được gửi.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  // Fetch booking detail for invoice
                  final resp = await _customerService.getBookingDetail(
                    widget.bookingId,
                  );

                  // Close loading
                  Navigator.of(context).pop();
                  // Close success dialog
                  Navigator.of(context).pop();

                  if (resp['success'] == true && resp['data'] != null) {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InvoiceScreen(booking: resp['data']),
                        ),
                      );
                    }
                  } else {
                    // Fallback to home if fetch fails
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                } catch (e) {
                  print('Error fetching invoice: $e');
                  // Close loading if error
                  Navigator.of(context).pop();
                  // Close success dialog
                  Navigator.of(context).pop();
                  // Fallback to home
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
              child: const Text('Xem Hóa Đơn'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentFailed(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('❌ Thanh toán thất bại'),
          content: Text(message),
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

/// WebView widget để hiển thị trang thanh toán VNPay
class VNPayWebView extends StatefulWidget {
  final String paymentUrl;
  final int bookingId;
  final Future<Map<String, dynamic>> Function({
    required String responseCode,
    String? transactionNo,
  })
  onPaymentComplete;

  const VNPayWebView({
    Key? key,
    required this.paymentUrl,
    required this.bookingId,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<VNPayWebView> createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('📄 WebView loading: $url');
            // Only show loading on initial load or if explicitly needed.
            // Removing this prevents the spinner from blocking the view during redirects/SPA navigation
            // setState(() => _isLoading = true);
            _checkPaymentCallback(url);
          },
          onPageFinished: (String url) {
            print('✅ WebView loaded: $url');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            print('❌ Error URL: ${error.url}');
            print('❌ Error Type: ${error.errorType}');

            // Check if the error URL is the callback URL (e.g. localhost)
            // If so, try to parse it anyway
            if (error.url != null && error.url!.isNotEmpty) {
              if (_checkPaymentCallback(error.url!)) {
                // Successfully handled callback, dismiss loading
                setState(() => _isLoading = false);
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔄 Navigation request: ${request.url}');
            if (_checkPaymentCallback(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _checkPaymentCallback(String url) {
    print('🔍 Checking URL: $url');

    // Kiểm tra nếu URL chứa VNPay callback parameters
    if (url.contains('vnp_ResponseCode') || url.contains('response_code')) {
      try {
        Uri? uri;
        try {
          uri = Uri.parse(url);
        } catch (e) {
          // Nếu parse URL thất bại (localhost), thử extract query string
          final queryStart = url.indexOf('?');
          if (queryStart != -1) {
            final queryString = url.substring(queryStart);
            uri = Uri.parse('http://localhost$queryString');
          }
        }

        if (uri != null) {
          final responseCode =
              uri.queryParameters['vnp_ResponseCode'] ??
              uri.queryParameters['response_code'] ??
              'unknown';
          final transactionNo =
              uri.queryParameters['vnp_TransactionNo'] ??
              uri.queryParameters['transaction_no'];

          print(
            '✅ Payment callback detected: responseCode=$responseCode, txnNo=$transactionNo',
          );

          // Gọi callback handler
          widget
              .onPaymentComplete(
                responseCode: responseCode,
                transactionNo: transactionNo,
              )
              .then((result) {
                if (mounted) {
                  Navigator.pop(context, result); // Trả về result map
                }
              });
          return true;
        }
      } catch (e) {
        print('❌ Error parsing callback URL: $e');
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán VNPay'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Return null on cancel
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
