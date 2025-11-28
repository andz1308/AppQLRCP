import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/seat.dart';
import '../../services/movie_service.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'booking_food_screen.dart';
import 'payment_screen.dart';

class BookingSeatScreen extends StatefulWidget {
  final Movie movie;
  final Showtime showtime;

  const BookingSeatScreen({
    Key? key,
    required this.movie,
    required this.showtime,
  }) : super(key: key);

  @override
  _BookingSeatScreenState createState() => _BookingSeatScreenState();
}

class _BookingSeatScreenState extends State<BookingSeatScreen> {
  final MovieService _movieService = MovieService();
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();

  List<Seat> _seats = [];
  final Set<int> _selectedSeatIds = {};
  bool _isLoading = true;
  bool _isBooking = false;

  int _totalRows = 0;
  int _totalColumns = 0;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    setState(() => _isLoading = true);
    try {
      // Request flat layout so client can choose a responsive display
      final data = await _movieService.getSeats(
        widget.showtime.showtimeId,
        flat: true,
      );
      setState(() {
        final rawSeats = (data['seats'] as List?) ?? [];
        if (rawSeats.isNotEmpty && rawSeats.first is Seat) {
          _seats = List<Seat>.from(rawSeats);
        } else {
          _seats = rawSeats.map((s) => Seat.fromJson(s)).toList();
        }

        // Normalize columns if backend uses 0-based column indices (e.g., 0..9)
        final colsList = _seats.map((s) => s.column).toList();
        if (colsList.isNotEmpty) {
          final minCol = colsList.reduce((a, b) => a < b ? a : b);
          if (minCol == 0) {
            _seats = _seats.map((s) {
              final oldCol = s.column;
              final newCol = oldCol + 1;
              String newSeatNumber = s.seatNumber;
              // If seatNumber was generated as row+oldCol (e.g., A0), update it
              final rowPrefix = s.row;
              if (rowPrefix.isNotEmpty) {
                final regex = RegExp('^' + RegExp.escape(rowPrefix) + r'\d+$');
                // If seatNumber empty or matches pattern like A0, A1, update to new column
                if (newSeatNumber.isEmpty || regex.hasMatch(newSeatNumber)) {
                  newSeatNumber = '$rowPrefix$newCol';
                }
              }
              return Seat(
                seatId: s.seatId,
                seatNumber: newSeatNumber,
                row: s.row,
                column: newCol,
                status: s.status,
                price: s.price,
                seatTypeId: s.seatTypeId,
                seatTypeName: s.seatTypeName,
                surcharge: s.surcharge,
              );
            }).toList();
          }
        }

        _totalRows = (data['rows'] is int && (data['rows'] as int) > 0)
            ? data['rows'] as int
            : _inferRowsFromSeats();
        _totalColumns = (data['columns'] is int && (data['columns'] as int) > 0)
            ? data['columns'] as int
            : _inferColumnsFromSeats();

        // Debug: log seat grid info
        print(
          '🪑 Loaded ${_seats.length} seats for grid ${_totalRows}x${_totalColumns}',
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ghế: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _inferRowsFromSeats() {
    final rows = _seats.map((s) => s.row).toSet().toList()..sort();
    return rows.length;
  }

  int _inferColumnsFromSeats() {
    final cols = _seats.map((s) => s.column).toSet().toList()..sort();
    if (cols.isEmpty) return 0;
    final minCol = cols.first;
    final maxCol = cols.last;
    return (maxCol - minCol + 1);
  }

  void _toggleSeat(int seatId) {
    setState(() {
      if (_selectedSeatIds.contains(seatId))
        _selectedSeatIds.remove(seatId);
      else
        _selectedSeatIds.add(seatId);
    });
  }

  Future<void> _handleBooking() async {
    if (_selectedSeatIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ghế'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final foodResult = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingFoodScreen(
          movie: widget.movie,
          showtime: widget.showtime,
          selectedSeatIds: _selectedSeatIds.toList(),
        ),
      ),
    );

    if (foodResult == null) return;
    final foodItems = foodResult['foodItems'] as List<Map<String, dynamic>>;

    final user = await _authService.getCurrentUser();
    if (user == null) return;

    setState(() => _isBooking = true);
    final result = await _bookingService.createBooking(
      showtimeId: widget.showtime.showtimeId,
      seatIds: _selectedSeatIds.toList(),
      foods: foodItems.isEmpty ? [] : foodItems,
    );
    setState(() => _isBooking = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đặt vé thành công'),
          backgroundColor: AppTheme.success,
        ),
      );

      // Get booking ID from response
      final bookingId = result['data']?['booking_id'] as int? ?? 0;
      final ticketTotal = result['data']?['ticket_total'] as num? ?? 0;
      final foodTotal = result['data']?['food_total'] as num? ?? 0;
      final totalAmount = (ticketTotal + foodTotal).toDouble();

      // Navigate to payment screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              movie: widget.movie,
              showtime: widget.showtime,
              bookingId: bookingId,
              selectedSeatIds: _selectedSeatIds.toList(),
              foodItems: foodItems,
              totalAmount: totalAmount,
              ticketTotal: ticketTotal.toDouble(),
              foodTotal: foodTotal.toDouble(),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đặt vé thất bại'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Widget _buildSeatsGrid() {
    if (_seats.isEmpty)
      return const Center(child: Text('Không có dữ liệu ghế'));
    // If backend returned rows==0 (flat layout), render a responsive grid that fits screen
    if (_totalRows == 0) {
      final int n = _seats.length;
      final screenWidth = MediaQuery.of(context).size.width - 32; // padding
      // Choose roughly square layout: columns ~= sqrt(n)
      int columns = (n > 0) ? math.sqrt(n).ceil() : 1;
      // ensure at least 1 and at most n columns
      columns = columns.clamp(1, n);

      // compute seat size to fit in available width
      final double spacing = 8.0; // margin between seats
      final double seatSize = (screenWidth - (columns - 1) * spacing) / columns;

      return Center(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: _seats.map((seat) {
            final isSelected = _selectedSeatIds.contains(seat.seatId);
            return SizedBox(
              width: seatSize,
              height: seatSize,
              child: _SeatWidget(
                seat: seat,
                isSelected: isSelected,
                size: seatSize,
                labelFontSize: (seatSize * 0.28).clamp(8.0, 14.0),
                onTap: seat.isAvailable ? () => _toggleSeat(seat.seatId) : null,
              ),
            );
          }).toList(),
        ),
      );
    }

    final allRows = List<String>.generate(
      _totalRows,
      (i) => String.fromCharCode(65 + i),
    );
    final aisleColumn = (_totalColumns / 2).ceil();

    // Fixed seat size; allow horizontal scrolling rather than shrinking
    const double seatSize = 44.0;
    // Compute a dynamic label font size so numbers shrink when there are many columns
    final screenWidth =
        MediaQuery.of(context).size.width - 32; // account for padding
    final int columns = _totalColumns > 0 ? _totalColumns : 1;
    // approximate horizontal space per seat including margins
    final double seatTotalWidth =
        seatSize + (seatSize * 0.18) * 2; // margin approx
    final double requiredWidth = columns * seatTotalWidth;
    double labelFontSize = (seatSize * 0.32);
    if (requiredWidth > screenWidth) {
      final scale = screenWidth / requiredWidth;
      labelFontSize = (labelFontSize * scale).clamp(8.0, seatSize * 0.32);
    }

    Widget seatFor(String row, int column) {
      final matches = _seats.where((s) => s.row == row && s.column == column);
      if (matches.isEmpty) return SizedBox(width: seatSize, height: seatSize);

      final seat = matches.first;
      final isSelected = _selectedSeatIds.contains(seat.seatId);
      return SizedBox(
        width: seatSize,
        height: seatSize,
        child: _SeatWidget(
          seat: seat,
          isSelected: isSelected,
          size: seatSize,
          labelFontSize: labelFontSize,
          onTap: seat.isAvailable ? () => _toggleSeat(seat.seatId) : null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: allRows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...List.generate(_totalColumns, (colIndex) {
                final colNumber = colIndex + 1;
                if (colNumber == aisleColumn + 1) {
                  return Row(
                    children: [
                      SizedBox(width: seatSize * 0.25),
                      seatFor(row, colNumber),
                    ],
                  );
                }
                return seatFor(row, colNumber);
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = 0;
    for (var id in _selectedSeatIds) {
      final match = _seats.where((x) => x.seatId == id);
      if (match.isNotEmpty) totalPrice += match.first.price;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn ghế')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.paleOrange,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.movie.title, style: AppTheme.headingSmall),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.showtime.cinema} - ${widget.showtime.room}',
                        style: AppTheme.bodyMedium,
                      ),
                      Text(
                        '${widget.showtime.date} - ${widget.showtime.startTime}',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MÀN HÌNH',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildSeatsGrid(),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.paleOrange,
                    border: Border(top: BorderSide(color: AppTheme.lightGray)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _LegendItem(
                          color: Colors.white,
                          label: 'Trống',
                          border: true,
                        ),
                        SizedBox(width: 16),
                        _LegendItem(
                          color: AppTheme.primaryOrange,
                          label: 'Đang chọn',
                        ),
                        SizedBox(width: 16),
                        _LegendItem(
                          color: AppTheme.mediumGray,
                          label: 'Đã đặt',
                        ),
                        SizedBox(width: 16),
                        _LegendItem(color: Color(0xFFC0392B), label: 'VIP'),
                        SizedBox(width: 16),
                        _LegendItem(color: Color(0xFFD6296D), label: 'Đôi'),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ghế đã chọn: ${_selectedSeatIds.length}',
                            style: AppTheme.bodyLarge,
                          ),
                          Text(
                            '${totalPrice.toStringAsFixed(0)}đ',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isBooking ? null : _handleBooking,
                          child: _isBooking
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Đặt vé'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final Seat seat;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;
  final double? labelFontSize;

  const _SeatWidget({
    Key? key,
    required this.seat,
    required this.isSelected,
    this.onTap,
    this.size = 44.0,
    this.labelFontSize,
  }) : super(key: key);

  Color _getBackgroundColor() {
    if (seat.isBooked) return AppTheme.mediumGray;
    if (isSelected) return const Color(0xFF1565C0);
    if (!seat.isAvailable) return Colors.transparent;
    if (seat.isVIP) return const Color(0xFFC0392B);
    if (seat.isCouple) return const Color(0xFFD6296D);
    return const Color(0xFF3498DB);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final borderColor = seat.isAvailable && !isSelected
        ? AppTheme.lightGray
        : backgroundColor;
    final label = (seat.seatNumber.isNotEmpty)
        ? seat.seatNumber
        : '${seat.row}${seat.column}';
    final defaultFontSize = (size * 0.32).clamp(10.0, 14.0);
    final fontSize = (labelFontSize ?? defaultFontSize).clamp(
      8.0,
      defaultFontSize,
    );
    final borderRadius = (size * 0.18).clamp(4.0, 8.0);
    final margin = (size * 0.09).clamp(2.0, 6.0);

    return Center(
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          margin: EdgeInsets.all(margin),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool border;

  const _LegendItem({
    Key? key,
    required this.color,
    required this.label,
    this.border = false,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            border: border ? Border.all(color: AppTheme.lightGray) : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.bodySmall),
      ],
    );
  }
}
