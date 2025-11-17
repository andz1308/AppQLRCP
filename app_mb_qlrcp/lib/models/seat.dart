class Seat {
  final int seatId;
  final String seatNumber;
  final String row;
  final int column;
  final String status; // "available", "booked", "aisle"
  final double price;
  final int? seatTypeId; // 1=Standard, 2=VIP, 3=Couple
  final String? seatTypeName; // "Standard", "VIP", "Couple"
  final double surcharge; // phí phụ thêm

  Seat({
    required this.seatId,
    required this.seatNumber,
    required this.row,
    required this.column,
    required this.status,
    required this.price,
    this.seatTypeId,
    this.seatTypeName,
    this.surcharge = 0,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    final seatType = json['seat_type'] as Map<String, dynamic>?;

    // ✅ Handle row: Could be String (from API) or int (from old format)
    String rowValue = '';
    final rowData = json['row'];
    if (rowData is String) {
      rowValue = rowData;
    } else if (rowData is int) {
      rowValue = String.fromCharCode(65 + rowData); // Convert 0->A, 1->B, etc.
    }

    return Seat(
      seatId: json['seat_id'] ?? 0,
      seatNumber: json['seat_number'] ?? '',
      row: rowValue,
      column: json['column'] ?? 0,
      status: json['status'] ?? 'available',
      price: (json['price'] ?? 0).toDouble(),
      seatTypeId: seatType?['type_id'] as int?,
      seatTypeName: seatType?['name'] as String?,
      surcharge: (seatType?['surcharge'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seat_id': seatId,
      'seat_number': seatNumber,
      'row': row,
      'column': column,
      'status': status,
      'price': price,
      'seat_type': {
        'type_id': seatTypeId,
        'name': seatTypeName,
        'surcharge': surcharge,
      },
    };
  }

  bool get isAvailable => status == 'available';
  bool get isBooked => status == 'booked';
  bool get isAisle => status == 'aisle';

  bool get isVIP => seatTypeId == 2;
  bool get isCouple => seatTypeId == 3;
  bool get isStandard => seatTypeId == 1 || seatTypeId == null;
}
