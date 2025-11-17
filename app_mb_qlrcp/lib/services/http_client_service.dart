import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/api_constants.dart';

/// Singleton Dio Client with persistent cookie jar.
/// Automatically handles cookies from login and includes them in subsequent requests.
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  late Dio _dio;
  late CookieJar _cookieJar;
  bool _cookieJarInitialized = false;

  factory HttpClientService() {
    return _instance;
  }

  HttpClientService._internal() {
    // Initialize with in-memory cookie jar first
    _cookieJar = CookieJar();
    _initCookieJar();

    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptor to handle cookies and fix Host header
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Fix Host header for SSL certificate validation
          options.headers['Host'] = ApiConstants.serverHostHeader;

          // Ensure cookie jar is initialized
          if (!_cookieJarInitialized) {
            await _initCookieJar();
          }

          try {
            // Normalize URI to use the server hostname so cookies saved with domain=localhost
            // are correctly loaded when running from the Android emulator (10.0.2.2).
            // Try loading cookies for both the actual request host and localhost
            final uriActual = options.uri;
            final uriLocal = Uri(
              scheme: options.uri.scheme,
              host: 'localhost',
              port: 44300,
              path: options.uri.path,
            );

            // Also try loading from root path as fallback
            final uriRoot = Uri(
              scheme: options.uri.scheme,
              host: options.uri.host,
              port: options.uri.port,
              path: '/',
            );
            final uriLocalRoot = Uri(
              scheme: options.uri.scheme,
              host: 'localhost',
              port: 44300,
              path: '/',
            );

            final cookiesActual = await _cookieJar.loadForRequest(uriActual);
            final cookiesLocal = await _cookieJar.loadForRequest(uriLocal);
            final cookiesRoot = await _cookieJar.loadForRequest(uriRoot);
            final cookiesLocalRoot = await _cookieJar.loadForRequest(
              uriLocalRoot,
            );

            // Merge cookie lists (remove duplicates by name)
            final cookieMap = <String, Cookie>{};
            for (final c in [
              ...cookiesActual,
              ...cookiesLocal,
              ...cookiesRoot,
              ...cookiesLocalRoot,
            ]) {
              cookieMap[c.name] = c;
            }

            if (cookieMap.isNotEmpty) {
              final cookieHeader = cookieMap.values
                  .map((c) => '${c.name}=${c.value}')
                  .join('; ');
              options.headers['Cookie'] = cookieHeader;
              print(
                '🍪 Loaded ${cookieMap.length} cookies for ${options.uri.path}',
              );
            } else {
              print('⚠️ No cookies found for ${options.uri.path}');
            }

            // Debug: log headers for booking-related endpoints to help diagnose 401
            final p = options.uri.path;
            if (p.contains('/create-booking') || p.contains('/bookings')) {
              print('➡️ Outgoing request to $p');
              print('➡️ Request headers: ${options.headers}');
            }
          } catch (e) {
            print('⛔ Cookie loading error: $e');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // Ensure cookie jar is initialized
          if (!_cookieJarInitialized) {
            await _initCookieJar();
          }

          try {
            final setCookieHeaders = response.headers['set-cookie'];
            if (setCookieHeaders != null && setCookieHeaders.isNotEmpty) {
              print(
                '🔐 Received ${setCookieHeaders.length} Set-Cookie headers from ${response.requestOptions.uri.path}',
              );
              final cookies = <Cookie>[];
              for (final header in setCookieHeaders) {
                try {
                  final cookie = Cookie.fromSetCookieValue(header);
                  cookies.add(cookie);
                  print(
                    '  Cookie: ${cookie.name}=${cookie.value} (domain=${cookie.domain}, path=${cookie.path})',
                  );
                } catch (e) {
                  // Ignore invalid headers
                }
              }
              if (cookies.isNotEmpty) {
                // Save cookies under both the actual request host and localhost
                try {
                  final uriActual = response.requestOptions.uri;
                  await _cookieJar.saveFromResponse(uriActual, cookies);
                  print(
                    '🔐 Saved ${cookies.length} cookies for ${uriActual.host}${uriActual.path}',
                  );
                } catch (_) {}
                try {
                  final uriLocal = Uri(
                    scheme: response.requestOptions.uri.scheme,
                    host: 'localhost',
                    port: 44300,
                    path: response
                        .requestOptions
                        .uri
                        .path, // Use actual path not hardcoded /
                  );
                  await _cookieJar.saveFromResponse(uriLocal, cookies);
                  print(
                    '🔐 Saved ${cookies.length} cookies for localhost:44300${uriLocal.path}',
                  );
                } catch (_) {}
              }
            }
          } catch (e) {
            // Ignore cookie save errors
          }
          return handler.next(response);
        },
      ),
    );
  }

  Future<void> _initCookieJar() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final cookiePath = '${appDocDir.path}/.cookies';
      _cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));
      _cookieJarInitialized = true;
      print('🍪 Cookie jar initialized at: $cookiePath');
    } catch (e) {
      print('⚠️ Failed to init persistent cookies, using in-memory: $e');
      _cookieJar = CookieJar(); // Fallback to in-memory
      _cookieJarInitialized = true;
    }
  }

  Dio get client => _dio;

  void close() {
    _dio.close();
  }

  // Debug helper: load cookies for a given server-relative path and return them.
  Future<List<Cookie>> debugLoadCookiesForPath(String path) async {
    try {
      // Use server root when loading cookies for debugging so it matches saveFromResponse
      final uri = Uri(
        scheme: 'https',
        host: 'localhost',
        port: 44300,
        path: '/',
      );
      return await _cookieJar.loadForRequest(uri);
    } catch (e) {
      return [];
    }
  }

  // Debug helper: print cookies for a given path to console.
  Future<void> debugPrintCookiesForPath(String path) async {
    final cookies = await debugLoadCookiesForPath(path);
    final dump = cookies.map((c) => '${c.name}=${c.value}').join('; ');
    print('🔐 CookieJar for $path -> $dump');
  }

  /// Returns a Cookie header string for the given server-relative path, or
  /// null if no cookies are stored for that path.
  Future<String?> getCookieHeaderForPath(String path) async {
    try {
      final uri = Uri(
        scheme: 'https',
        host: 'localhost',
        port: 44300,
        path: path,
      );
      final cookies = await _cookieJar.loadForRequest(uri);
      if (cookies.isEmpty) return null;
      return cookies.map((c) => '${c.name}=${c.value}').join('; ');
    } catch (e) {
      return null;
    }
  }
}

/// Global function to get the Dio client
Dio getHttpClient() {
  return HttpClientService().client;
}
