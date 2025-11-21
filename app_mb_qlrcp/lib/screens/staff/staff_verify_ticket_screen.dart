import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _qrCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyTicket() async {
    final qrCode = _qrCodeController.text.trim();
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
              _buildTicketInfo(
                'Suất chiếu',
                result['data']['showtime'] ?? 'N/A',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soát vé'),
        backgroundColor: AppTheme.primaryOrange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 100, color: AppTheme.primaryOrange),
            const SizedBox(height: 24),
            Text(
              'Nhập mã QR để soát vé',
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Nhập hoặc dán mã QR từ vé của khách hàng',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _qrCodeController,
              enabled: !_isVerifying,
              decoration: InputDecoration(
                labelText: 'Mã QR',
                hintText: 'Nhập mã QR của vé',
                prefixIcon: const Icon(Icons.qr_code_2),
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
                onPressed: _isVerifying ? null : _verifyTicket,
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
                label: Text(_isVerifying ? 'Đang xác thực...' : 'Xác thực vé'),
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
    );
  }
}
