class MovieDetail {
  final int movieId;
  final String title;
  final String description;
  final int duration;
  final DateTime? releaseDate;
  final String? image;
  final String? video;
  final Map<String, dynamic>? director;
  final double avgRating;
  final int reviewCount;
  final List<Map<String, dynamic>> genres;
  final List<Map<String, dynamic>> actors;
  final List<Map<String, dynamic>> showtimes;

  MovieDetail({
    required this.movieId,
    required this.title,
    required this.description,
    required this.duration,
    this.releaseDate,
    this.image,
    this.video,
    this.director,
    required this.avgRating,
    required this.reviewCount,
    required this.genres,
    required this.actors,
    required this.showtimes,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail(
      movieId: json['movie_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'].toString())
          : null,
      image: json['image'],
      video: json['video'],
      director: json['director'],
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      genres: List<Map<String, dynamic>>.from(json['genres'] ?? []),
      actors: List<Map<String, dynamic>>.from(json['actors'] ?? []),
      showtimes: List<Map<String, dynamic>>.from(json['showtimes'] ?? []),
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
      'video': video,
      'director': director,
      'avg_rating': avgRating,
      'review_count': reviewCount,
      'genres': genres,
      'actors': actors,
      'showtimes': showtimes,
    };
  }
}
