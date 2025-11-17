import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../utils/app_theme.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _bookingService = BookingService();
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingDetail();
  }

  Future<void> _loadBookingDetail() async {
    setState(() => _isLoading = true);

    final result = await _bookingService.getBookingDetail(widget.bookingId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _booking = result['booking'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đặt vé')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy thông tin đặt vé',
                    style: AppTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie title
                  Text(
                    _booking!.movieTitle ?? 'Phim',
                    style: AppTheme.headingLarge,
                  ),
                  const SizedBox(height: 16),

                  // Booking info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.confirmation_number,
                            label: 'Mã đặt vé',
                            value: '#${_booking!.bookingId}',
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Ngày đặt',
                            value: _booking!.createdAt,
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.event_seat,
                            label: 'Số vé',
                            value: '${_booking!.ticketsCount} vé',
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.info_outline,
                            label: 'Trạng thái',
                            value: _booking!.status,
                            valueColor: _booking!.isPaid
                                ? AppTheme.success
                                : _booking!.isPending
                                ? AppTheme.warning
                                : AppTheme.error,
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.attach_money,
                            label: 'Tổng tiền',
                            value: _booking!.totalAmountText,
                            valueColor: AppTheme.primaryOrange,
                            valueStyle: AppTheme.headingSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tickets
                  if (_booking!.tickets != null &&
                      _booking!.tickets!.isNotEmpty) ...[
                    Text('Vé của bạn', style: AppTheme.headingMedium),
                    const SizedBox(height: 12),
                    ...(_booking!.tickets!.map(
                      (ticket) => _TicketCard(ticket: ticket),
                    )),
                  ],
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    valueStyle ??
                    AppTheme.bodyLarge.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghế ${ticket.seatNumber}',
                      style: AppTheme.headingSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.ticketStatus,
                      style: AppTheme.bodySmall.copyWith(
                        color: ticket.isUsed
                            ? AppTheme.mediumGray
                            : AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (ticket.qrCode != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.lightGray),
                    ),
                    child: QrImageView(
                      data: ticket.qrCode!,
                      version: QrVersions.auto,
                      size: 80,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
