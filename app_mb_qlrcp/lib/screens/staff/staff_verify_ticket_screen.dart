import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide Barcode;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../../services/staff_service.dart';
import '../../utils/app_theme.dart';

class StaffVerifyTicketScreen extends StatefulWidget {
  final int? showtimeId;
  final Map<String, dynamic>? showtimeInfo;

  const StaffVerifyTicketScreen({
    super.key,
    this.showtimeId,
    this.showtimeInfo,
  });

  @override
  State<StaffVerifyTicketScreen> createState() =>
      _StaffVerifyTicketScreenState();
}

class _StaffVerifyTicketScreenState extends State<StaffVerifyTicketScreen> {
  final _staffService = StaffService();
  final _qrCodeController = TextEditingController();
  bool _isVerifying = false;
  MobileScannerController? _scannerController;
  late final ImagePicker _imagePicker;
  late final BarcodeScanner _barcodeScanner;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _imagePicker = ImagePicker();
    _barcodeScanner = BarcodeScanner();
  }

  @override
  void dispose() {
    _qrCodeController.dispose();
    _scannerController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _verifyTicket([String? code]) async {
    final qrCode = code ?? _qrCodeController.text.trim();
    if (qrCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã QR')));
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Gọi API với showtime_id nếu có
      final result = await _staffService.verifyTicket(
        qrCode,
        showtimeId: widget.showtimeId,
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSuccessDialog(result);
          _qrCodeController.clear();
        } else {
          _showErrorDialog(result['message'] ?? 'Xác thực thất bại');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vé hợp lệ',
                style: TextStyle(color: Colors.green, fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result['message'] ?? '✅ Vé hợp lệ - Đã soát thành công',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (result['data'] != null) ...[
                _buildInfoSection('Thông tin khách hàng', [
                  _buildTicketInfo(
                    Icons.person,
                    'Khách hàng',
                    result['data']['customer_name'] ?? 'N/A',
                  ),
                  if (result['data']['customer_phone'] != null &&
                      result['data']['customer_phone'] != 'N/A')
                    _buildTicketInfo(
                      Icons.phone,
                      'SĐT',
                      result['data']['customer_phone'],
                    ),
                ]),
                const Divider(height: 24),
                _buildInfoSection('Thông tin phim', [
                  _buildTicketInfo(
                    Icons.movie,
                    'Phim',
                    result['data']['movie_title'] ?? 'N/A',
                  ),
                  _buildTicketInfo(
                    Icons.location_on,
                    'Rạp',
                    result['data']['cinema_name'] ?? 'N/A',
                  ),
                  if (result['data']['room_name'] != null)
                    _buildTicketInfo(
                      Icons.meeting_room,
                      'Phòng',
                      result['data']['room_name'],
                    ),
                ]),
                const Divider(height: 24),
                _buildInfoSection('Thông tin suất chiếu', [
                  _buildTicketInfo(
                    Icons.calendar_today,
                    'Ngày',
                    result['data']['showtime_date'] ?? 'N/A',
                  ),
                  _buildTicketInfo(
                    Icons.access_time,
                    'Giờ',
                    result['data']['showtime_time'] ?? 'N/A',
                  ),
                ]),
                const Divider(height: 24),
                _buildInfoSection('Thông tin ghế', [
                  _buildTicketInfo(
                    Icons.event_seat,
                    'Số ghế',
                    result['data']['seat_number'] ?? 'N/A',
                  ),
                  if (result['data']['seat_location'] != null)
                    _buildTicketInfo(
                      Icons.location_searching,
                      'Vị trí',
                      result['data']['seat_location'],
                    ),
                  if (result['data']['ticket_price'] != null)
                    _buildTicketInfo(
                      Icons.attach_money,
                      'Giá vé',
                      '${result['data']['ticket_price']} đ',
                    ),
                ]),
                const Divider(height: 24),
                if (result['data']['verified_at'] != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đã soát lúc: ${result['data']['verified_at']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Tiếp tục quét'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Không hợp lệ',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
            label: const Text('Đóng'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildTicketInfo(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQrFromImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile == null) return;

      setState(() => _isVerifying = true);

      try {
        final InputImage inputImage = InputImage.fromFilePath(pickedFile.path);
        final List<Barcode> barcodes = await _barcodeScanner.processImage(
          inputImage,
        );

        if (barcodes.isEmpty) {
          if (mounted) {
            _showErrorDialog('Không tìm thấy mã QR trong ảnh');
          }
        } else {
          // Lấy mã QR đầu tiên
          final qrCode = barcodes.first.rawValue;
          if (qrCode != null && mounted) {
            await _verifyTicket(qrCode);
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog('Lỗi đọc ảnh: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isVerifying = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Lỗi chọn ảnh: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text('Soát vé', style: TextStyle(fontSize: 18)),
              if (widget.showtimeInfo != null)
                Text(
                  '${widget.showtimeInfo!['movie_title'] ?? ''} - ${widget.showtimeInfo!['start_time'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          backgroundColor: AppTheme.primaryOrange,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            overlayColor: MaterialStatePropertyAll(Colors.transparent),
            tabs: [
              Tab(icon: Icon(Icons.keyboard), text: 'Nhập mã'),
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'Camera QR'),
              Tab(icon: Icon(Icons.image), text: 'Ảnh QR'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Banner thông tin suất chiếu
            if (widget.showtimeInfo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.movie,
                          color: AppTheme.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.showtimeInfo!['movie_title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.showtimeInfo!['date']} - ${widget.showtimeInfo!['start_time']}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${widget.showtimeInfo!['cinema']} - ${widget.showtimeInfo!['room']}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Nhập mã
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_square,
                          size: 80,
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Nhập mã vé thủ công',
                          style: AppTheme.headingMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _qrCodeController,
                          enabled: !_isVerifying,
                          decoration: InputDecoration(
                            labelText: 'Mã vé',
                            hintText: 'Nhập mã vé của khách hàng',
                            prefixIcon: const Icon(Icons.confirmation_number),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onSubmitted: (_) => _verifyTicket(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isVerifying
                                ? null
                                : () => _verifyTicket(),
                            icon: _isVerifying
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
                                : const Icon(Icons.check_circle),
                            label: Text(
                              _isVerifying ? 'Đang xác thực...' : 'Xác thực vé',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Quét QR
                  Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null && !_isVerifying) {
                              _verifyTicket(barcode.rawValue!);
                              break; // Only process the first code
                            }
                          }
                        },
                      ),
                      // Overlay
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryOrange,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Text(
                          'Di chuyển camera đến mã QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            backgroundColor: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                      if (_isVerifying)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),

                  // Tab 3: Quét từ ảnh
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_search,
                          size: 80,
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Quét QR từ ảnh',
                          style: AppTheme.headingMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chọn ảnh chứa mã QR từ thư viện hình ảnh của bạn',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isVerifying ? null : _scanQrFromImage,
                            icon: _isVerifying
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
                                : const Icon(Icons.photo_library),
                            label: Text(
                              _isVerifying
                                  ? 'Đang xử lý...'
                                  : 'Chọn ảnh từ thư viện',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
