import 'package:dio/dio.dart';
import '../models/seat.dart';
import '../utils/api_constants.dart';
import '../utils/request_headers.dart';
import 'http_client_service.dart';

class StaffService {
  Future<Map<String, dynamic>> getDashboard(int staffId) async {
    try {
      final dio = getHttpClient();
      final response = await dio.get('${ApiConstants.staffDashboard}/$staffId');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {'success': true, 'data': data['data']};
        }
      }
      return {'success': false, 'message': 'Không thể tải thống kê'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getShowtimes(String url) async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {'success': data['success'], 'data': data['data']};
      }
      return {'success': false, 'message': 'Lỗi tải suất chiếu'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getSeats(int showtimeId) async {
    try {
      final dio = getHttpClient();
      final response = await dio.get('${ApiConstants.staffSeats}/$showtimeId');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'seats': (data['data'] as List)
                .map((item) => Seat.fromJson(item))
                .toList(),
          };
        }
      }
      return {'success': false, 'seats': [], 'message': 'Không có ghế nào'};
    } catch (e) {
      return {'success': false, 'seats': [], 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int showtimeId,
    required List<int> seatIds,
    required String customerPhone,
    required String customerName,
    List<Map<String, dynamic>>? foods,
    String? notes,
  }) async {
    try {
      final dio = getHttpClient();
      final response = await dio.post(
        '${ApiConstants.apiStaff}/create-booking',
        options: Options(headers: jsonHeaders()),
        data: {
          'showtime_id': showtimeId,
          'seats': seatIds,
          'customer_phone': customerPhone,
          'customer_name': customerName,
          'foods': foods ?? [],
          'notes': notes ?? '',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': data['success'],
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'Lỗi tạo đơn'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getBookings(String url) async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {'success': data['success'], 'data': data['data']};
      }
      return {'success': false, 'message': 'Lỗi tải đơn đặt'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyTicket(String qrCode) async {
    try {
      final dio = getHttpClient();
      final response = await dio.post(
        '${ApiConstants.apiStaff}/verify-ticket',
        options: Options(headers: jsonHeaders()),
        data: {'qr_code': qrCode},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': data['success'],
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'Xác thực thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }
}
