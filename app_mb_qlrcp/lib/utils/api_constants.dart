class ApiConstants {
  // TODO: Thay đổi URL này thành địa chỉ IP/domain của máy chủ web
  // Ví dụ: 'http://192.168.1.100' hoặc 'https://yourserver.com'
  // Sử dụng 10.0.2.2 cho Android emulator để kết nối đến máy host
  static const String baseUrl =
      'https://10.0.2.2:44300'; // Thay đổi theo môi trường

  static const String apiAuth = '$baseUrl/api/auth';
  static const String apiCustomer = '$baseUrl/api/customer';
  static const String apiStaff = '$baseUrl/api/staff';

  // When connecting from Android emulator to the host's HTTPS server
  // the request Host header must match the server's configured hostname.
  // The emulator uses 10.0.2.2 to reach the host, but the server expects
  // requests for 'localhost'. Set this to the hostname:port the server
  // is configured to accept.
  static const String serverHostHeader = 'localhost:44300';

  // Auth endpoints
  static const String login = '$apiAuth/login';
  static const String register = '$apiAuth/register';
  static const String profile = '$apiAuth/profile';

  // Customer endpoints
  static const String movies = '$apiCustomer/movies';
  static const String showtimes = '$apiCustomer/showtimes';
  static const String bookings = '$apiCustomer/bookings';
  static const String bookingDetail = '$apiCustomer/booking';
  static const String seats = '$apiCustomer/seats';
  static const String createBooking = '$apiCustomer/create-booking';
  static const String foods = '$apiCustomer/foods';
  static const String cinemas = '$apiCustomer/cinemas';
  static const String qrCode =
      '$apiCustomer/invoice'; // For QR code: /invoice/{bookingId}/qr-code

  // Staff endpoints
  static const String staffDashboard = '$apiStaff/dashboard';
  static const String staffShowtimes = '$apiStaff/showtimes';
  static const String staffSeats = '$apiStaff/seats';
  static const String staffCreateBooking = '$apiStaff/create-booking';
  static const String staffVerifyTicket = '$apiStaff/verify-ticket';
}
