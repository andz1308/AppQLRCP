import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class StaffBookingScreen extends StatelessWidget {
  final int staffId;

  const StaffBookingScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bán vé tại quầy')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.point_of_sale, size: 100, color: AppTheme.lightGray),
              const SizedBox(height: 24),
              Text(
                'Chức năng bán vé tại quầy',
                style: AppTheme.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Nhân viên có thể chọn suất chiếu và bán vé trực tiếp cho khách hàng tại quầy',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Tính năng đang được phát triển',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.warning,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
