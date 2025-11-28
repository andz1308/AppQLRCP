import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide Barcode;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../../services/staff_service.dart';
import '../../utils/app_theme.dart';

class StaffVerifyTicketScreen extends StatefulWidget {
  const StaffVerifyTicketScreen({super.key});

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
      final result = await _staffService.verifyTicket(qrCode);

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
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Vé hợp lệ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ?? '✅ Vé hợp lệ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            if (result['data'] != null) ...[
              _buildTicketInfo('Khách hàng', result['data']['customer_name']),
              _buildTicketInfo('Phim', result['data']['movie_title'] ?? 'N/A'),
              _buildTicketInfo('Ghế', result['data']['seat_number'] ?? 'N/A'),
              // _buildTicketInfo(
              //   'Suất chiếu',
              //   result['data']['showtime'] ?? 'N/A',
              // ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Resume scanning if needed
            },
            child: const Text('Tiếp tục quét'),
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
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Lỗi'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message, style: const TextStyle(fontSize: 16)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value ?? 'N/A')),
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
          title: const Text('Soát vé'),
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
        body: TabBarView(
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
                      onPressed: _isVerifying ? null : () => _verifyTicket(),
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
                    child: const Center(child: CircularProgressIndicator()),
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
                    style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
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
                        _isVerifying ? 'Đang xử lý...' : 'Chọn ảnh từ thư viện',
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
    );
  }
}
