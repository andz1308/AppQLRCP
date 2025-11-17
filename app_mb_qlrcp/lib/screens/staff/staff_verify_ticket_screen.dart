import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class StaffVerifyTicketScreen extends StatelessWidget {
  const StaffVerifyTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soát vé')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 100, color: AppTheme.lightGray),
              const SizedBox(height: 24),
              Text(
                'Quét mã QR để soát vé',
                style: AppTheme.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Nhân viên quét mã QR trên vé của khách hàng để xác nhận và đánh dấu vé đã sử dụng',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement QR scanner
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng quét QR đang được phát triển'),
                      backgroundColor: AppTheme.info,
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Quét mã QR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
