class Movie {
  final int movieId;
  final String title;
  final String? description;
  final int? duration; // phút
  final DateTime? releaseDate;
  final String? image;

  Movie({
    required this.movieId,
    required this.title,
    this.description,
    this.duration,
    this.releaseDate,
    this.image,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      movieId: json['movie_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      duration: json['duration'],
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'])
          : null,
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movie_id': movieId,
      'title': title,
      'description': description,
      'duration': duration,
      'release_date': releaseDate?.toIso8601String(),
      'image': image,
    };
  }

  String get durationText {
    if (duration == null) return 'N/A';
    return '$duration phút';
  }
}
