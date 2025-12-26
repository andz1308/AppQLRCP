import 'package:flutter/material.dart';
import '../../services/staff_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_theme.dart';
import 'staff_verify_ticket_screen.dart';

class StaffShowtimeSelectionScreen extends StatefulWidget {
  const StaffShowtimeSelectionScreen({super.key});

  @override
  State<StaffShowtimeSelectionScreen> createState() =>
      _StaffShowtimeSelectionScreenState();
}

class _StaffShowtimeSelectionScreenState
    extends State<StaffShowtimeSelectionScreen> {
  final _staffService = StaffService();
  List<Map<String, dynamic>> _showtimes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
  }

  Future<void> _loadShowtimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Lấy suất chiếu hôm nay
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final url = '${ApiConstants.staffShowtimes}?date=$dateStr';
    print('📡 Calling API: $url');

    final result = await _staffService.getShowtimes(url);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final data = result['data'];
          print('✅ API Success: ${data?.length ?? 0} showtimes');
          if (data is List) {
            // Lọc các suất chiếu đủ điều kiện (30 phút trước đến 1 giờ sau)
            _showtimes = _filterValidShowtimes(
              List<Map<String, dynamic>>.from(
                data.map((e) => Map<String, dynamic>.from(e)),
              ),
            );
            print('🎬 Filtered: ${_showtimes.length} valid showtimes');
          }
        } else {
          final errorMsg = result['message'] ?? 'Không thể tải suất chiếu';
          print('❌ API Error: $errorMsg');
          _errorMessage = errorMsg;
        }
      });
    }
  }

  List<Map<String, dynamic>> _filterValidShowtimes(
    List<Map<String, dynamic>> showtimes,
  ) {
    final now = DateTime.now();
    final validShowtimes = <Map<String, dynamic>>[];

    for (final showtime in showtimes) {
      try {
        final dateStr = showtime['date']?.toString() ?? '';
        final timeStr = showtime['start_time']?.toString() ?? '';

        if (dateStr.isEmpty || timeStr.isEmpty) continue;

        // Parse date và time
        final dateParts = dateStr.split('-');
        final timeParts = timeStr.split(':');

        if (dateParts.length != 3 || timeParts.length < 2) continue;

        final showtimeDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        // Kiểm tra điều kiện: 30 phút trước đến 1 giờ sau
        final allowedStart = showtimeDate.subtract(const Duration(minutes: 30));
        final allowedEnd = showtimeDate.add(const Duration(hours: 1));

        if (now.isAfter(allowedStart) && now.isBefore(allowedEnd)) {
          validShowtimes.add(showtime);
        }
      } catch (e) {
        // Skip invalid showtime
        continue;
      }
    }

    return validShowtimes;
  }

  void _onShowtimeSelected(Map<String, dynamic> showtime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffVerifyTicketScreen(
          showtimeId: showtime['showtime_id'] as int,
          showtimeInfo: showtime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn suất chiếu'),
        backgroundColor: AppTheme.primaryOrange,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShowtimes,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadShowtimes,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            )
          : _showtimes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Không có suất chiếu nào đủ điều kiện soát vé',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(Chỉ hiển thị suất chiếu trong khoảng\n30 phút trước đến 1 giờ sau giờ chiếu)',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadShowtimes,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Làm mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadShowtimes,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _showtimes.length,
                itemBuilder: (context, index) {
                  final showtime = _showtimes[index];
                  return _ShowtimeCard(
                    showtime: showtime,
                    onTap: () => _onShowtimeSelected(showtime),
                  );
                },
              ),
            ),
    );
  }
}

class _ShowtimeCard extends StatelessWidget {
  final Map<String, dynamic> showtime;
  final VoidCallback onTap;

  const _ShowtimeCard({required this.showtime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final movieTitle = showtime['movie_title']?.toString() ?? 'N/A';
    final cinema = showtime['cinema']?.toString() ?? 'N/A';
    final room = showtime['room']?.toString() ?? 'N/A';
    final date = showtime['date']?.toString() ?? 'N/A';
    final time = showtime['start_time']?.toString() ?? 'N/A';
    final totalSeats = showtime['total_seats']?.toString() ?? '0';
    final bookedSeats = showtime['booked_seats']?.toString() ?? '0';
    final availableSeats = showtime['available_seats']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      movieTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on, cinema),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.meeting_room, 'Phòng $room'),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.calendar_today, date),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSeatInfo('Tổng ghế', totalSeats, Colors.blue),
                  ),
                  Expanded(
                    child: _buildSeatInfo('Đã đặt', bookedSeats, Colors.orange),
                  ),
                  Expanded(
                    child: _buildSeatInfo(
                      'Còn trống',
                      availableSeats,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Chọn để soát vé',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
