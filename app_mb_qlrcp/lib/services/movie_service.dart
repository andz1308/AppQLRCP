import '../models/cinema.dart';
import '../models/food.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../models/seat.dart';
import '../models/showtime.dart';
import '../utils/api_constants.dart';
import 'http_client_service.dart';

class MovieService {
  // GetMovies: data: { movies: [...], total, current_page, ... }
  Future<Map<String, dynamic>> getMovies() async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(ApiConstants.movies);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] is Map) {
          final responseData = data['data'] as Map<String, dynamic>;
          final moviesList = responseData['movies'] as List? ?? [];
          return {
            'success': true,
            'movies': moviesList.map((item) => Movie.fromJson(item)).toList(),
            'message': data['message'] ?? 'Lấy danh sách phim thành công',
          };
        }
        return {
          'success': false,
          'movies': [],
          'message': data['message'] ?? 'Không có phim nào',
        };
      }
      return {
        'success': false,
        'movies': [],
        'message': 'Failed: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'movies': [], 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMovieDetail(int movieId) async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(
        '${ApiConstants.apiCustomer}/movie/$movieId',
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        print('🎬 MovieDetail API Response: $data');
        if (data['success'] == true && data['data'] != null) {
          final movieDetailData = data['data'] as Map<String, dynamic>;
          print('📹 Video: ${movieDetailData['video']}');
          print('🎥 Showtimes: ${movieDetailData['showtimes']}');
          return {
            'success': true,
            'movie': MovieDetail.fromJson(movieDetailData),
            'message': data['message'],
          };
        }
      }
      return {'success': false, 'message': 'Phim không tồn tại'};
    } catch (e) {
      print('❌ MovieDetail Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // GetShowtimes: data: [...] (danh sách trực tiếp)
  Future<Map<String, dynamic>> getShowtimes(int movieId) async {
    try {
      final dio = getHttpClient();
      final response = await dio.get('${ApiConstants.showtimes}/$movieId');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] is List) {
          final showtimesList = data['data'] as List? ?? [];
          return {
            'success': true,
            'showtimes': showtimesList
                .map((item) => Showtime.fromJson(item))
                .toList(),
            'message': data['message'] ?? 'Lấy danh sách suất chiếu thành công',
          };
        }
        return {
          'success': false,
          'showtimes': [],
          'message': data['message'] ?? 'Không có suất chiếu nào',
        };
      }
      return {
        'success': false,
        'showtimes': [],
        'message': 'Failed: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'showtimes': [], 'message': 'Error: $e'};
    }
  }

  // GetSeats: data: { seats, rows, columns, ... } (object)
  Future<Map<String, dynamic>> getSeats(int showtimeId) async {
    try {
      final dio = getHttpClient();
      // Backend seats endpoint is: /api/customer/seats/{showtimeId}
      print(
        '➡️ Requesting seats for showtimeId=$showtimeId -> ${ApiConstants.seats}/$showtimeId',
      );
      final response = await dio.get('${ApiConstants.seats}/$showtimeId');
      print('⬅️ Seats response status: ${response.statusCode}');
      try {
        print('⬅️ Seats response data: ${response.data}');
      } catch (_) {}
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] is Map) {
          final seatData = data['data'] as Map<String, dynamic>;
          final seatsList = (seatData['seats'] as List?) ?? [];
          final rows = seatData['rows'] as int? ?? 0;
          final columns = seatData['columns'] as int? ?? 0;
          return {
            'success': true,
            'seats': seatsList.map((item) => Seat.fromJson(item)).toList(),
            'rows': rows,
            'columns': columns,
            'message': data['message'] ?? 'Lấy danh sách ghế thành công',
          };
        }
        return {
          'success': false,
          'seats': [],
          'rows': 0,
          'columns': 0,
          'message': data['message'] ?? 'Không có ghế nào',
        };
      }
      return {
        'success': false,
        'seats': [],
        'rows': 0,
        'columns': 0,
        'message': 'Failed: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'seats': [],
        'rows': 0,
        'columns': 0,
        'message': 'Error: $e',
      };
    }
  }

  // GetFoods: data: [...] (danh sách trực tiếp)
  Future<Map<String, dynamic>> getFoods() async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(ApiConstants.foods);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] is List) {
          final foodsList = data['data'] as List? ?? [];
          return {
            'success': true,
            'foods': foodsList.map((item) => Food.fromJson(item)).toList(),
            'message': data['message'] ?? 'Lấy danh sách đồ ăn thành công',
          };
        }
        return {
          'success': false,
          'foods': [],
          'message': data['message'] ?? 'Không có đồ ăn nào',
        };
      }
      return {
        'success': false,
        'foods': [],
        'message': 'Failed: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'foods': [], 'message': 'Error: $e'};
    }
  }

  // GetCinemas: data: [...] (danh sách trực tiếp)
  Future<Map<String, dynamic>> getCinemas() async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(ApiConstants.cinemas);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] is List) {
          final cinemasList = data['data'] as List? ?? [];
          return {
            'success': true,
            'cinemas': cinemasList
                .map((item) => Cinema.fromJson(item))
                .toList(),
            'message': data['message'] ?? 'Lấy danh sách rạp thành công',
          };
        }
        return {
          'success': false,
          'cinemas': [],
          'message': data['message'] ?? 'Không có rạp nào',
        };
      }
      return {
        'success': false,
        'cinemas': [],
        'message': 'Failed: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'cinemas': [], 'message': 'Error: $e'};
    }
  }

  // GetMovieReviews: TODO - endpoint chưa implement trong backend
  Future<Map<String, dynamic>> getMovieReviews(int movieId) async {
    try {
      // Endpoint reviews chưa có trong API backend
      // Trả về empty list mà không gọi API
      return {
        'success': true,
        'reviews': [],
        'message': 'Không có đánh giá nào',
      };
    } catch (e) {
      return {'success': false, 'reviews': [], 'message': 'Error: $e'};
    }
  }
}
