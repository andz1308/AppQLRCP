class Booking {
  final int bookingId;
  final String createdAt;
  final String status;
  final double totalAmount;
  final int ticketsCount;
  final String? movieTitle;
  final List<Ticket>? tickets;
  final List<FoodItem>? foodItems;

  Booking({
    required this.bookingId,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.ticketsCount,
    this.movieTitle,
    this.tickets,
    this.foodItems,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      ticketsCount: json['tickets_count'] ?? 0,
      movieTitle: json['movie_title'],
      tickets: json['tickets'] != null
          ? (json['tickets'] as List).map((t) => Ticket.fromJson(t)).toList()
          : null,
      foodItems: json['food_items'] != null
          ? (json['food_items'] as List)
                .map((f) => FoodItem.fromJson(f))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'created_at': createdAt,
      'status': status,
      'total_amount': totalAmount,
      'tickets_count': ticketsCount,
      'movie_title': movieTitle,
      'tickets': tickets?.map((t) => t.toJson()).toList(),
      'food_items': foodItems?.map((f) => f.toJson()).toList(),
    };
  }

  String get totalAmountText {
    return '${totalAmount.toStringAsFixed(0)}đ';
  }

  bool get isPaid => status == 'Đã Thanh toán';
  bool get isPending =>
      status == 'Chưa thanh toán' || status == 'Chờ thanh toán';
  bool get isCancelled => status == 'Đã Hủy';
}

class Ticket {
  final int ticketId;
  final String seatNumber;
  final String ticketStatus;
  final String? qrCode;
  final double price;

  Ticket({
    required this.ticketId,
    required this.seatNumber,
    required this.ticketStatus,
    this.qrCode,
    required this.price,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'] ?? 0,
      seatNumber: json['seat_number'] ?? '',
      ticketStatus: json['status'] ?? json['ticket_status'] ?? '',
      qrCode: json['qr_code'],
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'seat_number': seatNumber,
      'status': ticketStatus,
      'qr_code': qrCode,
      'price': price,
    };
  }

  bool get isUsed => ticketStatus == 'Đã sử dụng';
  bool get isUnused => ticketStatus == 'Chưa sử dụng';
}

class FoodItem {
  final String foodName;
  final int quantity;
  final double price;

  FoodItem({
    required this.foodName,
    required this.quantity,
    required this.price,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      foodName: json['food_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'food_name': foodName, 'quantity': quantity, 'price': price};
  }

  String get totalText {
    return '${(price * quantity).toStringAsFixed(0)}đ';
  }
}
