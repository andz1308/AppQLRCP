import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../utils/app_theme.dart';
import 'booking_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  final int customerId;

  const BookingHistoryScreen({super.key, required this.customerId});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    final result = await _bookingService.getBookings();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result.containsKey('bookings')) {
          final bookingsList = result['bookings'] as List;
          _bookings = bookingsList.cast<Booking>();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vé của tôi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 80,
                    color: AppTheme.lightGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có vé nào',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  return _BookingCard(
                    booking: booking,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailScreen(bookingId: booking.bookingId),
                        ),
                      ).then((_) => _loadBookings());
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (booking.isPaid) {
      statusColor = AppTheme.success;
    } else if (booking.isPending) {
      statusColor = AppTheme.warning;
    } else {
      statusColor = AppTheme.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.movieTitle ?? 'Phim',
                      style: AppTheme.headingSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status,
                      style: AppTheme.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text(booking.createdAt, style: AppTheme.bodySmall),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text('${booking.ticketsCount} vé', style: AppTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng tiền:', style: AppTheme.bodyMedium),
                  Text(
                    booking.totalAmountText,
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
