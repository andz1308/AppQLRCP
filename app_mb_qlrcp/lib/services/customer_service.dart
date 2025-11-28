import 'package:dio/dio.dart';
import '../utils/api_constants.dart';
import '../utils/request_headers.dart';
import 'http_client_service.dart';

class CustomerService {
  Future<Map<String, dynamic>> getMovies({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(
        ApiConstants.movies,
        queryParameters: {'page': page, 'pageSize': pageSize},
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getShowtimes(int movieId, {String? date}) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.showtimes}/$movieId';
      final qp = <String, dynamic>{};
      if (date != null && date.isNotEmpty) qp['date'] = date;
      final response = await dio.get(
        url,
        queryParameters: qp,
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getFoods() async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(
        ApiConstants.foods,
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'foods': data['data'] ?? [],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getCinemas() async {
    try {
      final dio = getHttpClient();
      final response = await dio.get(
        ApiConstants.cinemas,
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'cinemas': data['data'] ?? [],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getInvoice(int bookingId) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.qrCode}/$bookingId';
      final response = await dio.get(
        url,
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data;
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getInvoiceQRCode(int bookingId) async {
    final dio = getHttpClient();
    try {
      final url = '${ApiConstants.qrCode}/$bookingId/qr-code';
      final response = await dio.get(
        url,
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data;
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } on DioException catch (dioErr) {
      final status = dioErr.response?.statusCode;
      final serverData = dioErr.response?.data;
      print(
        '⛔ getInvoiceQRCode DioException: status=$status, data=$serverData',
      );
      return {
        'success': false,
        'message': 'HTTP ${status ?? 'error'}',
        'server': serverData,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getCustomerProfile(int customerId) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/profile/$customerId';
      final response = await dio.get(
        url,
        options: Options(headers: jsonHeaders()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data;
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateCustomerProfile(
    int customerId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/profile/$customerId';
      final response = await dio.put(
        url,
        options: Options(headers: jsonHeaders()),
        data: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data;
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> checkPromo(
    String promoCode,
    List<Map<String, dynamic>> foodItems,
  ) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/check-promo';
      final body = {'promo_code': promoCode, 'food_items': foodItems};
      final response = await dio.post(
        url,
        data: body,
        options: Options(headers: jsonHeaders()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> applyPromoToBooking(
    int bookingId,
    String promoCode, {
    double? originalTotal,
  }) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/booking/$bookingId/apply-promo';
      final body = <String, dynamic>{'promo_code': promoCode};
      if (originalTotal != null)
        body['original_total'] = originalTotal.toString();
      print('🔍 Calling apply-promo API: url=$url, body=$body');
      final response = await dio.post(
        url,
        data: body,
        options: Options(headers: jsonHeaders()),
      );
      print('🔍 Apply-promo response status: ${response.statusCode}');
      print('🔍 Apply-promo response data: ${response.data}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      print('❌ Apply-promo failed with status: ${response.statusCode}');
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ Apply-promo error: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getAvailablePromoCodes(
    int customerId,
    List<Map<String, dynamic>> foodItems,
  ) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/available-promos';
      final body = <String, dynamic>{
        'customer_id': customerId,
        'food_items': foodItems,
      };
      print('🔍 Calling available-promos API with customerId=$customerId');
      print('🔍 Request headers: ${jsonHeaders()}');
      final response = await dio.post(
        url,
        data: body,
        options: Options(headers: jsonHeaders()),
      );
      print('🔍 API Response Status: ${response.statusCode}');
      print('🔍 API Response Data: ${response.data}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'] ?? [],
        };
      }
      print('❌ API returned status: ${response.statusCode}');
      return {
        'success': false,
        'message': 'HTTP ${response.statusCode}',
        'data': [],
      };
    } catch (e) {
      print('❌ Error calling available-promos: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is DioException) {
        print('❌ DioException - Status: ${e.response?.statusCode}');
        print('❌ DioException - Data: ${e.response?.data}');
      }
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'data': [],
      };
    }
  }

  Future<Map<String, dynamic>> confirmQRPayment(
    int bookingId, {
    String? promoCode,
  }) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/confirm-qr-payment';
      final body = <String, dynamic>{'booking_id': bookingId};
      if (promoCode != null && promoCode.isNotEmpty)
        body['promo_code'] = promoCode;
      final response = await dio.post(
        url,
        data: body,
        options: Options(headers: jsonHeaders()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data,
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Process VNPay payment callback
  /// Gọi API process-vnpay-payment để xác thực thanh toán
  /// Get VNPay payment URL
  /// Lấy URL thanh toán VNPay để redirect user
  Future<Map<String, dynamic>> getVNPayPaymentUrl(int bookingId) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/get-vnpay-payment-url';
      final response = await dio.post(
        url,
        data: {'booking_id': bookingId},
        options: Options(headers: jsonHeaders()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> processVNPayPayment({
    required int bookingId,
    required String responseCode,
    String? transactionNo,
  }) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/process-vnpay-payment';
      final response = await dio.post(
        url,
        data: {
          'booking_id': bookingId,
          'response_code': responseCode,
          'transaction_no': transactionNo ?? '',
        },
        options: Options(headers: jsonHeaders()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data,
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getBookingDetail(int bookingId) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/booking/$bookingId';
      final response = await dio.get(
        url,
        options: Options(headers: jsonHeaders()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getMyTickets(int customerId) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/my-tickets/$customerId';
      final response = await dio.get(
        url,
        options: Options(headers: jsonHeaders()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> generateSeatQRCode(int ticketId) async {
    try {
      final dio = getHttpClient();
      final url = '${ApiConstants.apiCustomer}/generate-seat-qr';
      final response = await dio.post(
        url,
        data: {'ticket_id': ticketId},
        options: Options(headers: jsonHeaders()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Yêu cầu hủy vé (đã thanh toán) - Hoàn lại 70%
  Future<Map<String, dynamic>> requestCancelTicket({
    required int customerId,
    required int bookingId,
    required String reason,
  }) async {
    try {
      final dio = getHttpClient();
      final url = ApiConstants.requestCancel;
      final response = await dio.post(
        url,
        data: {
          'customer_id': customerId,
          'booking_id': bookingId,
          'reason': reason,
        },
        options: Options(headers: jsonHeaders()),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'data': data['data'],
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
