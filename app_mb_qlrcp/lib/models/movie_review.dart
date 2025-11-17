class MovieReview {
  final int reviewId;
  final String customerName;
  final int rating;
  final String content;
  final String date;

  MovieReview({
    required this.reviewId,
    required this.customerName,
    required this.rating,
    required this.content,
    required this.date,
  });

  factory MovieReview.fromJson(Map<String, dynamic> json) {
    return MovieReview(
      reviewId: json['review_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      rating: json['rating'] ?? 0,
      content: json['content'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'customer_name': customerName,
      'rating': rating,
      'content': content,
      'date': date,
    };
  }
}
