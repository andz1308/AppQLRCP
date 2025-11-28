import 'package:dio/dio.dart';
import '../models/booking.dart';
import '../utils/api_constants.dart';
import '../utils/request_headers.dart';
import 'http_client_service.dart';
import 'storage_service.dart';

class BookingService {
  Future<Map<String, dynamic>> getBookings() async {
    try {
      final dio = getHttpClient();
      // Debug: print cookies used for bookings request
      try {
        await HttpClientService().debugPrintCookiesForPath(
          '/api/customer/bookings',
        );
      } catch (_) {}
      // API expects customerId as query parameter
      final response = await dio.get('${ApiConstants.bookings}?customerId=1');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] is List) {
          final bookingsList = data['data'] as List? ?? [];
          return {
            'success': true,
            'bookings': bookingsList
                .map((item) => Booking.fromJson(item))
                .toList(),
            'message': data['message'] ?? 'Lấy danh sách đơn thành công',
          };
        }
        return {
          'success': false,
          'bookings': [],
          'message': data['message'] ?? 'Không có đơn nào',
        };
      }
      return {
        'success': false,
        'bookings': [],
        'message': 'Failed: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'bookings': [], 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getBookingDetail(int bookingId) async {
    try {
      final dio = getHttpClient();
      final response = await dio.get('${ApiConstants.bookings}/$bookingId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          try {
            final bookingJson = data['data'] as Map<String, dynamic>;
            final booking = Booking.fromJson(bookingJson);
            return {
              'success': true,
              'booking': booking,
              'message': data['message'] ?? 'Lấy chi tiết thành công',
            };
          } catch (_) {
            return {'success': false, 'message': 'Lỗi parse booking'};
          }
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Không tìm thấy thông tin',
        };
      } else {
        throw Exception(
          'Failed to load booking detail: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting booking detail: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int showtimeId,
    required List<int> seatIds,
    required List<Map<String, dynamic>> foods,
    String? notes,
  }) async {
    try {
      final dio = getHttpClient();

      // Get current user to include customer_id in request
      final storage = StorageService();
      final user = await storage.getUser();
      final customerId = user?.userId ?? 0;

      if (customerId <= 0) {
        return {
          'success': false,
          'message': 'Lỗi: Không tìm thấy thông tin khách hàng',
        };
      }

      // Debug: print cookies used for create-booking request
      try {
        await HttpClientService().debugPrintCookiesForPath(
          '/api/customer/create-booking',
        );
      } catch (_) {}
      // Debug: print cookies used for create-booking request
      try {
        await HttpClientService().debugPrintCookiesForPath('/');
      } catch (_) {}

      // Debug: print outgoing request headers/body
      try {
        final debugHeaders = <String, dynamic>{};
        debugHeaders.addAll({});
        print(
          '➡️ [createBooking] Sending request to ${ApiConstants.createBooking}',
        );
        // Can't access options until request, but print prepared body
        print(
          '➡️ [createBooking] Body: {customer_id: $customerId, showtime_id: $showtimeId, seat_ids: $seatIds, food_items: $foods, notes: ${notes ?? ""}}',
        );
      } catch (_) {}

      late Response response;
      try {
        // Try to explicitly include Cookie header for create-booking to
        // ensure server receives authentication cookie (workaround for
        // any header-key issues in interceptors).
        final headers = Map<String, String>.from(jsonHeaders());
        try {
          final cookieHeader = await HttpClientService().getCookieHeaderForPath(
            '/api/customer/create-booking',
          );
          if (cookieHeader != null && cookieHeader.isNotEmpty) {
            headers['Cookie'] = cookieHeader;
          }
        } catch (_) {}

        response = await dio.post(
          ApiConstants.createBooking,
          options: Options(headers: headers),
          data: {
            'customer_id': customerId,
            'showtime_id': showtimeId,
            'seat_ids': seatIds,
            'food_items': foods,
            'notes': notes ?? '',
          },
        );
      } catch (e) {
        // If DioException with response, log it for debugging
        try {
          // ignore: avoid_catching_errors
          final dioErr = e as DioException;
          if (dioErr.response != null) {
            print(
              '⛔ createBooking error response: ${dioErr.response?.statusCode} ${dioErr.response?.data}',
            );
          } else {
            print('⛔ createBooking error: $e');
          }
        } catch (_) {
          print('⛔ createBooking unexpected error: $e');
        }
        rethrow;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Tạo đơn đặt vé thành công',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Lỗi tạo đơn: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final dio = getHttpClient();
      final response = await dio.post(
        '${ApiConstants.bookings}/$bookingId/cancel',
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Hủy đơn thành công',
        };
      } else {
        return {
          'success': false,
          'message': 'Lỗi hủy đơn: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> createReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final dio = getHttpClient();
      final response = await dio.post(
        '${ApiConstants.bookings}/$bookingId/review',
        options: Options(headers: jsonHeaders()),
        data: {'rating': rating, 'comment': comment ?? ''},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Đánh giá thành công',
        };
      } else {
        return {
          'success': false,
          'message': 'Lỗi đánh giá: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getQRCode(int bookingId) async {
    final dio = getHttpClient();
    try {
      final response = await dio.get(
        '${ApiConstants.qrCode}/$bookingId/qr-code',
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] is Map) {
          return {
            'success': true,
            'qrCodeUrl': data['data']['qr_code_url'],
            'description': data['data']['description'],
            'amount': data['data']['amount'],
            'message': data['message'] ?? 'Lấy mã QR thành công',
          };
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Không tìm thấy dữ liệu',
        };
      }
      return {
        'success': false,
        'message': 'Lỗi lấy mã QR: ${response.statusCode}',
      };
    } on DioException catch (dioErr) {
      final status = dioErr.response?.statusCode;
      final serverData = dioErr.response?.data;
      print('⛔ getQRCode DioException: status=$status, data=$serverData');
      return {
        'success': false,
        'message': 'HTTP ${status ?? 'error'}',
        'server': serverData,
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }
}
