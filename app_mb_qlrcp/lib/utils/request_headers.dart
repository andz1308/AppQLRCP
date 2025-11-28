import 'api_constants.dart';

/// Returns common request headers for JSON APIs.
/// Includes a Host header to match the backend's expected hostname when
/// running from an emulator (10.0.2.2 -> host machine).
Map<String, String> jsonHeaders() {
  return {
    'Content-Type': 'application/json',
    'Host': ApiConstants.serverHostHeader,
  };
}
