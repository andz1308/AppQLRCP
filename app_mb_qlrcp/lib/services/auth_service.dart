import 'package:dio/dio.dart';
import '../models/user.dart';
import '../utils/api_constants.dart';
import '../utils/request_headers.dart';
import 'http_client_service.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final dio = getHttpClient();
      final response = await dio.post(
        ApiConstants.login,
        options: Options(headers: jsonHeaders()),
        data: {'email': email, 'password': password},
      );

      // Debug: show Set-Cookie headers returned by the server during login
      try {
        final setCookie = response.headers['set-cookie'];
        print('🔐 Set-Cookie headers on login: $setCookie');
      } catch (_) {}

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;

        if (data['success'] == true) {
          final user = User.fromJson(data['user']);
          await _storage.saveUser(user);

          // Debug: print cookies saved after successful login
          try {
            await HttpClientService().debugPrintCookiesForPath('/');
          } catch (_) {}

          return {
            'success': true,
            'user': user,
            'message': data['message'] ?? 'Đăng nhập thành công',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Đăng nhập thất bại',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final dio = getHttpClient();
      final response = await dio.post(
        ApiConstants.register,
        options: Options(headers: jsonHeaders()),
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Đăng ký thành công',
        };
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  Future<User?> getCurrentUser() async {
    return await _storage.getUser();
  }

  Future<void> logout() async {
    await _storage.clearUser();
  }
}
