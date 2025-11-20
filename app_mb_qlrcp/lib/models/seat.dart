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
    } else if (rowData is double) {
      // sometimes numeric comes as double
      rowValue = String.fromCharCode(65 + rowData.toInt());
    }

    // seat number fallback (treat "N/A" as missing)
    String seatNumber = '';
    final rawSeatNum = (json['seat_number'] ?? json['seatNumber'])?.toString();
    if (rawSeatNum != null &&
        rawSeatNum.trim().isNotEmpty &&
        rawSeatNum.trim().toLowerCase() != 'n/a') {
      seatNumber = rawSeatNum.trim();
    } else {
      // fallback to row+column if explicit seat number missing
      final col = json['column'] ?? json['col'] ?? 0;
      final colNum = (col is int)
          ? col
          : (col is double
                ? col.toInt()
                : int.tryParse(col?.toString() ?? '') ?? 0);
      seatNumber =
          (rowValue.isNotEmpty ? rowValue : '') +
          (colNum > 0 ? colNum.toString() : '');
    }

    // If row is missing but seatNumber contains a leading letter(s) (e.g., A10), extract row
    if (rowValue.isEmpty && seatNumber.isNotEmpty) {
      final match = RegExp(r'^([A-Za-z]+)').firstMatch(seatNumber);
      if (match != null) {
        rowValue = match.group(1) ?? '';
      }
    }

    // parse price robustly
    double priceValue = 0.0;
    final priceRaw = json['price'];
    if (priceRaw is int)
      priceValue = priceRaw.toDouble();
    else if (priceRaw is double)
      priceValue = priceRaw;
    else if (priceRaw is String)
      priceValue = double.tryParse(priceRaw) ?? 0.0;

    // parse seat type fields robustly
    int? parsedTypeId;
    String? parsedTypeName;
    double parsedSurcharge = 0.0;
    if (seatType != null) {
      final rawId =
          seatType['type_id'] ?? seatType['typeId'] ?? seatType['loaighe_id'];
      if (rawId is int)
        parsedTypeId = rawId;
      else if (rawId is double)
        parsedTypeId = rawId.toInt();
      else if (rawId is String)
        parsedTypeId = int.tryParse(rawId);

      parsedTypeName = (seatType['name'] ?? seatType['ten_loai'])?.toString();

      final rawS = seatType['surcharge'] ?? seatType['phu_phi'];
      if (rawS is int)
        parsedSurcharge = rawS.toDouble();
      else if (rawS is double)
        parsedSurcharge = rawS;
      else if (rawS is String)
        parsedSurcharge = double.tryParse(rawS) ?? 0.0;
    }

    return Seat(
      seatId: json['seat_id'] is int
          ? json['seat_id']
          : int.tryParse(json['seat_id']?.toString() ?? '') ?? 0,
      seatNumber: seatNumber,
      row: rowValue,
      column: json['column'] is int
          ? json['column']
          : (json['column'] is double
                ? (json['column'] as double).toInt()
                : int.tryParse(json['column']?.toString() ?? '') ?? 0),
      status: json['status'] ?? 'available',
      price: priceValue,
      seatTypeId: parsedTypeId,
      seatTypeName: parsedTypeName,
      surcharge: parsedSurcharge,
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
