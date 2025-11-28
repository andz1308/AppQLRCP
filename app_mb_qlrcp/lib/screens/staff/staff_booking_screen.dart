import 'package:flutter/material.dart';
import '../../services/staff_service.dart';
import '../../utils/api_constants.dart';

class StaffBookingScreen extends StatefulWidget {
  final int staffId;

  const StaffBookingScreen({super.key, required this.staffId});

  @override
  State<StaffBookingScreen> createState() => _StaffBookingScreenState();
}

class _StaffBookingScreenState extends State<StaffBookingScreen> {
  final _staffService = StaffService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _staffService.getBookings(
      '${ApiConstants.apiStaff}/bookings',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final data = result['data'];
          if (data is Map && data.containsKey('bookings')) {
            _bookings = data['bookings'];
          } else if (data is List) {
            _bookings = data;
          }
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text(
          'Bạn có chắc muốn hủy đơn đặt này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Có, Hủy'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _staffService.cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Đã hủy đơn')),
        );
        if (result['success'] == true) {
          _loadBookings();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đặt vé')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                final status = booking['status'] ?? '';
                final isCancelled = status == 'Đã Hủy';

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Mã đơn: ${booking['booking_id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Khách: ${booking['customer_name']}'),
                        Text('Ngày: ${booking['created_at']}'),
                        Text('Tổng tiền: ${booking['total_amount']}'),
                        Text(
                          'Trạng thái: $status',
                          style: TextStyle(
                            color: isCancelled ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    trailing: !isCancelled
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () =>
                                _cancelBooking(booking['booking_id']),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
