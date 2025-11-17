class Cinema {
  final int cinemaId;
  final String name;
  final String address;

  Cinema({required this.cinemaId, required this.name, required this.address});

  factory Cinema.fromJson(Map<String, dynamic> json) {
    return Cinema(
      cinemaId: json['cinema_id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'cinema_id': cinemaId, 'name': name, 'address': address};
  }
}
