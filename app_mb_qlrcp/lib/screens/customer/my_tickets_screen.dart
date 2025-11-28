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
        // API returns list directly in 'data'
        final ticketsData = (data is List)
            ? data
            : (data['tickets'] as List? ?? []);

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
                final showtimeDate = ticket['showtime_date'] ?? 'N/A';
                final showtimeTime = ticket['showtime_time'] ?? 'N/A';
                final status = ticket['status'] ?? 'N/A';
                final totalAmount = ticket['total_amount'] ?? 0;
                final ticketsCount = ticket['tickets_count'] ?? 0;
                // final canCancel = ticket['can_cancel'] ?? false;
                // final bookingId = ticket['booking_id'] ?? 0;

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
                        Text('📍 $cinema'),
                        Text('🎫 Số vé: $ticketsCount'),
                        Text('📅 $showtimeDate - $showtimeTime'),
                        Text('💰 Tổng: ${totalAmount.toString()} đ'),
                        Text(
                          'Trạng thái: $status',
                          style: TextStyle(
                            color: status == 'Đã Thanh toán'
                                ? Colors.green
                                : status == 'Đã Hủy'
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // if (canCancel) ...[
                        //   const SizedBox(height: 8),
                        //   ElevatedButton.icon(
                        //     onPressed: () => _showCancelDialog(bookingId),
                        //     icon: const Icon(Icons.cancel, size: 16),
                        //     label: const Text('Hủy vé'),
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.red,
                        //       minimumSize: const Size(0, 32),
                        //       padding: const EdgeInsets.symmetric(
                        //         horizontal: 12,
                        //       ),
                        //     ),
                        //   ),
                        // ],
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showTicketDetail(ticket);
                    },
                  ),
                );
              },
            ),
    );
  }

  // void _showCancelDialog(int bookingId) {
  //   final reasonController = TextEditingController();

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Xác nhận hủy vé'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             '⚠️ Bạn sẽ được hoàn lại 70% giá trị vé (trừ 30% phí hủy)',
  //             style: TextStyle(
  //               color: Colors.orange,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           TextField(
  //             controller: reasonController,
  //             decoration: const InputDecoration(
  //               labelText: 'Lý do hủy',
  //               hintText: 'Nhập lý do hủy vé...',
  //               border: OutlineInputBorder(),
  //             ),
  //             maxLines: 3,
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Đóng'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             _cancelTicket(bookingId, reasonController.text);
  //           },
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('Xác nhận hủy'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Future<void> _cancelTicket(int bookingId, String reason) async {
  //   if (reason.trim().isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Vui lòng nhập lý do hủy vé')),
  //     );
  //     return;
  //   }

  //   try {
  //     final result = await _customerService.requestCancelTicket(
  //       customerId: _customerId,
  //       bookingId: bookingId,
  //       reason: reason,
  //     );

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(result['message'] ?? 'Đã gửi yêu cầu hủy vé'),
  //           backgroundColor: result['success'] == true
  //               ? Colors.green
  //               : Colors.red,
  //         ),
  //       );

  //       if (result['success'] == true) {
  //         _loadMyTickets(); // Reload tickets
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
  //       );
  //     }
  //   }
  // }

  void _showTicketDetail(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bookingId = ticket['booking_id'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              Text(
                'Chi tiết vé',
                style: AppTheme.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Mã đơn:', '#$bookingId'),
              const Divider(),
              _buildDetailRow('Phim:', ticket['movie_title'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Rạp:', ticket['cinema'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Số vé:', '${ticket['tickets_count'] ?? 0}'),
              const Divider(),
              _buildDetailRow('Ngày chiếu:', ticket['showtime_date'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Giờ chiếu:', ticket['showtime_time'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Tổng tiền:', '${ticket['total_amount']} đ'),
              const Divider(),
              _buildDetailRow('Trạng thái:', ticket['status'] ?? 'N/A'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      // Copy to clipboard logic if needed
                    },
                    child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
