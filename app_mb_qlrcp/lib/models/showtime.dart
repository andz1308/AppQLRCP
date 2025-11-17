class Showtime {
  final int showtimeId;
  final String cinema;
  final String room;
  final String date;
  final String startTime;
  final double price;
  final int totalSeats;
  final int bookedSeats;
  final int availableSeats;
  final String? movieTitle;

  Showtime({
    required this.showtimeId,
    required this.cinema,
    required this.room,
    required this.date,
    required this.startTime,
    required this.price,
    required this.totalSeats,
    required this.bookedSeats,
    required this.availableSeats,
    this.movieTitle,
  });

  factory Showtime.fromJson(Map<String, dynamic> json) {
    return Showtime(
      showtimeId: json['showtime_id'] ?? 0,
      cinema: json['cinema'] ?? '',
      room: json['room'] ?? '',
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      totalSeats: json['total_seats'] ?? 0,
      bookedSeats: json['booked_seats'] ?? 0,
      availableSeats: json['available_seats'] ?? 0,
      movieTitle: json['movie_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showtime_id': showtimeId,
      'cinema': cinema,
      'room': room,
      'date': date,
      'start_time': startTime,
      'price': price,
      'total_seats': totalSeats,
      'booked_seats': bookedSeats,
      'available_seats': availableSeats,
      'movie_title': movieTitle,
    };
  }

  String get priceText {
    return '${price.toStringAsFixed(0)}đ';
  }

  bool get isAvailable => availableSeats > 0;
}
