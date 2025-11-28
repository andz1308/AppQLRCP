import 'dart:io';

import 'api_constants.dart';

/// Development-only HTTP overrides to accept self-signed certificates for
/// localhost / emulator hosts. Do NOT enable this in production.
class MyHttpOverrides extends HttpOverrides {
  final bool allowBadCertificate;

  MyHttpOverrides({this.allowBadCertificate = true});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);

    if (allowBadCertificate) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
            // Allow only known development hosts
            final allowedHosts = <String>{'localhost', '127.0.0.1', '10.0.2.2'};

            // Also allow if host matches the ApiConstants baseUrl host
            try {
              final uriHost = Uri.parse(ApiConstants.baseUrl).host;
              allowedHosts.add(uriHost);
            } catch (_) {}

            return allowedHosts.contains(host);
          };
    }

    return client;
  }
}
