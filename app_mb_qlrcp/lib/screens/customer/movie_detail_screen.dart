import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/movie_detail.dart';
import '../../models/movie_review.dart';
import '../../services/movie_service.dart';
import '../../utils/app_theme.dart';
import 'booking_seat_screen.dart';
import 'trailer_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _movieService = MovieService();
  MovieDetail? _movieDetail;
  List<MovieReview> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMovieDetail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMovieDetail() async {
    setState(() => _isLoading = true);

    final result = await _movieService.getMovieDetail(widget.movie.movieId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _movieDetail = result['movie'];
          _loadReviews();
        }
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);

    final result = await _movieService.getMovieReviews(widget.movie.movieId);

    if (mounted) {
      setState(() {
        _isLoadingReviews = false;
        if (result['success'] == true) {
          _reviews = result['reviews'];
        }
      });
    }
  }

  Future<void> _watchTrailer() async {
    if (_movieDetail?.video == null || _movieDetail!.video!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có trailer cho phim này')),
      );
      return;
    }

    // Open dedicated trailer screen with embedded YouTube player
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailerScreen(
          trailerUrl: _movieDetail!.video,
          movieTitle: _movieDetail!.title,
        ),
      ),
    );
  }

  void _showShowtimesBottomSheet() {
    if (_movieDetail == null || _movieDetail!.showtimes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có suất chiếu nào')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.mediumGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Chọn suất chiếu', style: AppTheme.headingSmall),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _movieDetail!.showtimes.length,
                itemBuilder: (context, index) {
                  final showtime = _movieDetail!.showtimes[index];
                  return _ShowtimeSelectionCard(
                    showtime: showtime,
                    movie: widget.movie,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingSeatScreen(
                            movie: widget.movie,
                            showtime: Showtime(
                              showtimeId: showtime['showtime_id'],
                              cinema: showtime['cinema'],
                              room: showtime['room'],
                              date: showtime['date'],
                              startTime: showtime['start_time'],
                              price: (showtime['price'] ?? 0).toDouble(),
                              totalSeats: 0,
                              bookedSeats: 0,
                              availableSeats: 0,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.movie.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie poster
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      image: widget.movie.image != null
                          ? DecorationImage(
                              image: NetworkImage(widget.movie.image!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: widget.movie.image == null
                        ? const Icon(
                            Icons.movie,
                            size: 80,
                            color: AppTheme.mediumGray,
                          )
                        : null,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.movie.title,
                                    style: AppTheme.headingLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 20,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(_movieDetail?.avgRating ?? 0).toStringAsFixed(1)} (${_movieDetail?.reviewCount ?? 0} đánh giá)',
                                        style: AppTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Info row
                        Row(
                          children: [
                            if (widget.movie.duration != null) ...[
                              const Icon(
                                Icons.access_time,
                                size: 20,
                                color: AppTheme.mediumGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.movie.durationText,
                                style: AppTheme.bodyMedium,
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (widget.movie.releaseDate != null) ...[
                              const Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: AppTheme.mediumGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.movie.releaseDate!.day}/${widget.movie.releaseDate!.month}/${widget.movie.releaseDate!.year}',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        if (widget.movie.description != null) ...[
                          Text('Mô tả', style: AppTheme.headingSmall),
                          const SizedBox(height: 8),
                          Text(
                            widget.movie.description!,
                            style: AppTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Director
                        if (_movieDetail?.director != null) ...[
                          Text('Đạo diễn', style: AppTheme.headingSmall),
                          const SizedBox(height: 8),
                          Text(
                            _movieDetail!.director!['name'] ?? 'N/A',
                            style: AppTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Genres
                        if (_movieDetail != null &&
                            _movieDetail!.genres.isNotEmpty) ...[
                          Text('Thể loại', style: AppTheme.headingSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _movieDetail!.genres
                                .map(
                                  (genre) => Chip(
                                    label: Text(genre['name'] ?? ''),
                                    backgroundColor: AppTheme.primaryOrange
                                        .withAlpha(30),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Cast
                        if (_movieDetail != null &&
                            _movieDetail!.actors.isNotEmpty) ...[
                          Text('Diễn viên', style: AppTheme.headingSmall),
                          const SizedBox(height: 8),
                          Text(
                            _movieDetail!.actors
                                .map(
                                  (actor) =>
                                      '${actor['name']} (${actor['role']})',
                                )
                                .join(', '),
                            style: AppTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _watchTrailer,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Xem Trailer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryOrange,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showShowtimesBottomSheet,
                                icon: const Icon(Icons.event_seat),
                                label: const Text('Đặt Vé'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Reviews section
                        if (_reviews.isNotEmpty) ...[
                          Text(
                            'Đánh giá của khách hàng',
                            style: AppTheme.headingSmall,
                          ),
                          const SizedBox(height: 12),
                          _isLoadingReviews
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _reviews.length,
                                  itemBuilder: (context, index) {
                                    final review = _reviews[index];
                                    return _ReviewCard(review: review);
                                  },
                                ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ShowtimeSelectionCard extends StatelessWidget {
  final Map<String, dynamic> showtime;
  final Movie movie;
  final VoidCallback onTap;

  const _ShowtimeSelectionCard({
    required this.showtime,
    required this.movie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showtime['cinema'] ?? 'N/A',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          showtime['room'] ?? 'N/A',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${showtime['price']}đ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        showtime['date'] ?? 'N/A',
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        showtime['start_time'] ?? 'N/A',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final MovieReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(review.customerName, style: AppTheme.headingSmall),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_outline,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.content, style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              review.date,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
            ),
          ],
        ),
      ),
    );
  }
}
