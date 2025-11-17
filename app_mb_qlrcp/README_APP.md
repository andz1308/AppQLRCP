# Cinema App - Ứng dụng Quản lý Rạp Chiếu Phim

Ứng dụng mobile quản lý rạp chiếu phim được xây dựng bằng Flutter, kết nối với backend API của hệ thống web.

## 🎨 Màu sắc chủ đạo
- **Màu cam chính**: #FF6B35 (Orange)
- Ứng dụng sử dụng màu cam làm màu chủ đạo cho toàn bộ giao diện

## 🚀 Tính năng

### Dành cho Khách hàng (Customer)
- ✅ Đăng nhập / Đăng ký tài khoản
- ✅ Xem danh sách phim đang chiếu
- ✅ Xem chi tiết phim và suất chiếu
- ✅ Đặt vé: chọn ghế, thanh toán
- ✅ Xem lịch sử đặt vé
- ✅ Xem chi tiết vé với mã QR
- ✅ Quản lý thông tin cá nhân

### Dành cho Nhân viên (Staff/Admin)
- ✅ Đăng nhập với tài khoản nhân viên
- ✅ Xem thống kê dashboard (doanh thu, vé bán, soát vé)
- ✅ Bán vé trực tiếp tại quầy (đang phát triển)
- ✅ Soát vé bằng QR code (đang phát triển)
- ✅ Quản lý thông tin cá nhân

## 📱 Cấu trúc ứng dụng

```
lib/
├── models/           # Data models (User, Movie, Showtime, Booking, Seat)
├── services/         # API services và business logic
│   ├── auth_service.dart
│   ├── movie_service.dart
│   ├── booking_service.dart
│   ├── staff_service.dart
│   └── storage_service.dart
├── screens/          # Màn hình giao diện
│   ├── customer/     # Màn hình khách hàng
│   ├── staff/        # Màn hình nhân viên
│   ├── login_screen.dart
│   └── register_screen.dart
├── utils/            # Utilities và constants
│   ├── app_theme.dart
│   └── api_constants.dart
└── main.dart         # Entry point
```

## ⚙️ Cài đặt và Chạy ứng dụng

### 1. Cài đặt Dependencies

```bash
cd app_mb_qlrcp
flutter pub get
```

### 2. Cấu hình API URL

Mở file `lib/utils/api_constants.dart` và thay đổi `baseUrl` thành địa chỉ server của bạn:

```dart
static const String baseUrl = 'https://localhost:44300'; // HTTPS với port 44300
```

**Lưu ý quan trọng**:
- Nếu chạy trên emulator Android: sử dụng `https://10.0.2.2:44300` để kết nối localhost
- Nếu chạy trên thiết bị thật: sử dụng `https://[IP_MÁY_TÍNH]:44300`
- Nếu deploy lên server: sử dụng `https://yourdomain.com`

**Cấu hình HTTPS cho development:**
- Đảm bảo backend hỗ trợ HTTPS (SSL certificate)
- Nếu sử dụng certificate tự ký, cần cấu hình network security config trong Android

### 3. Chạy ứng dụng

```bash
# Chạy trên Android
flutter run

# Chạy trên iOS
flutter run

# Chạy trên Chrome (Web)
flutter run -d chrome
```

## 📦 Dependencies chính

```yaml
dependencies:
  http: ^1.1.0              # HTTP requests
  provider: ^6.0.5          # State management
  shared_preferences: ^2.2.2 # Local storage
  intl: ^0.19.0             # Internationalization
  qr_flutter: ^4.1.0        # Generate QR codes
  qr_code_scanner: ^1.0.1   # Scan QR codes
```

## 🔐 Tài khoản Demo

### Khách hàng:
- Email: customer@example.com
- Password: 123456

### Nhân viên:
- Email: staff@example.com
- Password: 123456

## 🎯 Luồng hoạt động

### Luồng đặt vé (Customer)
1. Đăng nhập/Đăng ký
2. Xem danh sách phim → Chọn phim
3. Xem suất chiếu → Chọn suất chiếu
4. Chọn ghế ngồi
5. Xác nhận đặt vé
6. Nhận mã QR vé

### Luồng bán vé (Staff)
1. Đăng nhập với tài khoản nhân viên
2. Vào trang "Bán vé"
3. Chọn suất chiếu
4. Chọn ghế cho khách
5. Nhập thông tin khách hàng
6. In vé với QR code

### Luồng soát vé (Staff)
1. Vào trang "Soát vé"
2. Quét mã QR trên vé khách hàng
3. Xác nhận vé hợp lệ
4. Đánh dấu vé đã sử dụng

## 🛠️ API Endpoints

### Authentication
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/register` - Đăng ký
- `GET /api/auth/profile/{userId}` - Lấy profile

### Customer
- `GET /api/customer/movies` - Danh sách phim
- `GET /api/customer/showtimes/{movieId}` - Suất chiếu
- `GET /api/customer/seats/{showtimeId}` - Danh sách ghế
- `POST /api/customer/create-booking` - Tạo đơn đặt vé
- `GET /api/customer/bookings/{customerId}` - Lịch sử đặt vé
- `GET /api/customer/booking-detail/{bookingId}` - Chi tiết đặt vé

### Staff
- `GET /api/staff/dashboard/{staffId}` - Thống kê
- `GET /api/staff/showtimes` - Suất chiếu (cho bán vé)
- `GET /api/staff/seats/{showtimeId}` - Danh sách ghế
- `POST /api/staff/create-booking` - Bán vé offline
- `POST /api/staff/verify-ticket` - Soát vé QR

## 🐛 Troubleshooting

### Lỗi kết nối API
- Kiểm tra `baseUrl` trong `api_constants.dart`
- Đảm bảo server đang chạy
- Kiểm tra firewall/network

### Lỗi dependencies
```bash
flutter clean
flutter pub get
```

### Lỗi build Android
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

## 📝 TODO - Tính năng cần phát triển

- [ ] Hoàn thiện chức năng bán vé offline cho Staff
- [ ] Tích hợp camera để quét QR code soát vé
- [ ] Thêm chức năng thanh toán online (VNPay, Momo)
- [ ] Thêm chức năng đánh giá phim
- [ ] Push notification cho thông báo đặt vé
- [ ] Dark mode
- [ ] Đa ngôn ngữ (Tiếng Việt/English)

## 👨‍💻 Phát triển bởi

Ứng dụng được xây dựng dựa trên hệ thống web WebQLRCP hiện có.

## 📄 License

Copyright © 2025
