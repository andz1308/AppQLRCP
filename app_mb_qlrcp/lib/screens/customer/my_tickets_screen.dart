import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({Key? key}) : super(key: key);

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final CustomerService _customerService = CustomerService();
  late int _customerId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyTickets();
  }

  Future<void> _loadMyTickets() async {
    try {
      setState(() => _isLoading = true);

      final storage = StorageService();
      final user = await storage.getUser();
      _customerId = user?.userId ?? 0;

      if (_customerId <= 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không tìm thấy thông tin khách hàng';
        });
        return;
      }

      final resp = await _customerService.getMyTickets(_customerId);

      if (resp['success'] == true && resp['data'] != null) {
        final data = resp['data'];
        final ticketsData = data['tickets'] as List? ?? [];
        setState(() {
          _tickets = List<Map<String, dynamic>>.from(
            ticketsData.cast<Map<String, dynamic>>(),
          );
          _isLoading = false;
        });
        print('✅ Loaded ${_tickets.length} tickets');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = resp['message'] ?? 'Lỗi tải vé';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vé của tôi'),
        backgroundColor: AppTheme.primaryOrange,
        centerTitle: true,
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
                    onPressed: _loadMyTickets,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : _tickets.isEmpty
          ? const Center(child: Text('Bạn chưa có vé nào'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                final movieTitle = ticket['movie_title'] ?? 'N/A';
                final cinema = ticket['cinema'] ?? 'N/A';
                final room = ticket['room'] ?? 'N/A';
                final seatNumber = ticket['seat_number'] ?? 'N/A';
                final date = ticket['showtime_date'] ?? 'N/A';
                final time = ticket['showtime_time'] ?? 'N/A';
                final status = ticket['status'] ?? 'N/A';
                final price = ticket['price'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      movieTitle,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('📍 $cinema - $room'),
                        Text('🪑 Ghế: $seatNumber'),
                        Text('📅 $date - $time'),
                        Text('💰 Giá: $price đ'),
                        Text(
                          'Trạng thái: $status',
                          style: TextStyle(
                            color: status == 'Đã sử dụng'
                                ? Colors.green
                                : status == 'Bị hủy'
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      _showTicketDetail(ticket);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showTicketDetail(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final qrCode = ticket['qr_code'] ?? 'N/A';
        final bookingStatus = ticket['booking_status'] ?? 'N/A';

        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chi tiết vé',
                  style: AppTheme.headingSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Phim:', ticket['movie_title'] ?? 'N/A'),
                _buildDetailRow('Rạp:', ticket['cinema'] ?? 'N/A'),
                _buildDetailRow('Phòng:', ticket['room'] ?? 'N/A'),
                _buildDetailRow('Ghế:', ticket['seat_number'] ?? 'N/A'),
                _buildDetailRow(
                  'Ngày chiếu:',
                  ticket['showtime_date'] ?? 'N/A',
                ),
                _buildDetailRow('Giờ chiếu:', ticket['showtime_time'] ?? 'N/A'),
                _buildDetailRow(
                  'Mã vé:',
                  qrCode.length > 20 ? '${qrCode.substring(0, 20)}...' : qrCode,
                ),
                _buildDetailRow('Giá:', '${ticket['price']} đ'),
                _buildDetailRow('Trạng thái:', ticket['status'] ?? 'N/A'),
                _buildDetailRow('Trạng thái đơn:', bookingStatus),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
