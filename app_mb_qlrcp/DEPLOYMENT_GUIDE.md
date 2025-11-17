# 🎬 HƯỚNG DẪN TRIỂN KHAI ỨNG DỤNG CINEMA APP

## 📋 Tổng quan

Ứng dụng Cinema App là một ứng dụng mobile được xây dựng bằng Flutter, kết nối với backend API từ hệ thống web WebQLRCP. Ứng dụng có 2 giao diện riêng biệt:
- **Customer (Khách hàng)**: Xem phim, đặt vé, quản lý vé
- **Staff (Nhân viên)**: Thống kê, bán vé tại quầy, soát vé

## 🎨 Thiết kế

### Màu sắc chủ đạo: CAM (#FF6B35)
- Primary Orange: #FF6B35
- Dark Orange: #E85D25
- Light Orange: #FF8C5F
- Pale Orange: #FFF3EF

## 🚀 BƯỚC 1: CÀI ĐẶT MÔI TRƯỜNG

### Yêu cầu hệ thống:
- Flutter SDK 3.10.0 trở lên
- Dart SDK
- Android Studio / Xcode (tùy platform)
- VS Code hoặc Android Studio IDE

### Kiểm tra Flutter:
```bash
flutter doctor
```

## 🔧 BƯỚC 2: CẤU HÌNH PROJECT

### 1. Di chuyển vào thư mục project:
```bash
cd d:\APPMBQLRCP\app_mb_qlrcp
```

### 2. Cài đặt dependencies:
```bash
flutter pub get
```

### 3. Cấu hình API URL:

Mở file `lib/utils/api_constants.dart` và thay đổi `baseUrl`:

```dart
static const String baseUrl = 'https://localhost:44300'; // HTTPS với port 44300
```

**Lưu ý quan trọng:**
- Ứng dụng sử dụng HTTPS để bảo mật
- Đảm bảo backend hỗ trợ HTTPS với SSL certificate
- Network security config đã được cấu hình cho development

**Các trường hợp cụ thể:**

#### A. Chạy trên Android Emulator (HTTPS):
```dart
static const String baseUrl = 'https://10.0.2.2:44300'; 
// 10.0.2.2 là địa chỉ localhost của máy host từ emulator
```

#### B. Chạy trên thiết bị thật (HTTPS):
```dart
static const String baseUrl = 'https://192.168.1.100:44300'; 
// Thay bằng IP máy tính đang chạy server
```

Cách lấy IP máy tính:
- Windows: `ipconfig`
- Mac/Linux: `ifconfig`

#### C. Server trên internet (HTTPS):
```dart
static const String baseUrl = 'https://yourdomain.com';
```

**Quan trọng:** Đảm bảo backend hỗ trợ HTTPS với SSL certificate hợp lệ.
```

## 🖥️ BƯỚC 3: CHUẨN BỊ BACKEND

### 1. Cấu hình HTTPS cho Web API:
- Mở project WebCinema trong Visual Studio
- Cấu hình SSL certificate trong IIS Express hoặc IIS
- Đảm bảo API chạy trên HTTPS port 44300

**Cách cấu hình HTTPS trong Visual Studio:**
1. Right-click project → Properties
2. Tab "Debug" → Enable SSL = True
3. Copy SSL URL (https://localhost:44300)
4. Update launchSettings.json nếu cần

### 2. Đảm bảo Web API đang chạy:
- Khởi động project WebCinema với HTTPS
- API endpoints phải accessible từ mobile device
- Kiểm tra CORS đã được cấu hình

### 3. Test API:
Dùng Postman hoặc browser test endpoint:
```
https://localhost:44300/api/auth/login
```

### 4. Cấu hình firewall (nếu cần):
- Windows: Cho phép port 443 qua Windows Firewall
- Tắt tạm thời firewall để test

## 📱 BƯỚC 4: CHẠY ỨNG DỤNG

### 1. Kết nối thiết bị hoặc mở emulator:
```bash
flutter devices
```

### 2. Chạy app:
```bash
# Chạy mode debug
flutter run

# Chạy mode release (nhanh hơn)
flutter run --release

# Chọn device cụ thể
flutter run -d <device_id>
```

### 3. Hot reload trong quá trình dev:
- Nhấn `r` để reload
- Nhấn `R` để restart
- Nhấn `q` để thoát

## 🔐 BƯỚC 5: TEST ỨNG DỤNG

### Tài khoản test Customer:
```
Email: customer@example.com
Password: 123456
```

### Tài khoản test Staff:
```
Email: staff@example.com  
Password: 123456
```

### Test flow Customer:
1. Mở app → Màn hình Login
2. Chọn "Đăng ký" để tạo tài khoản mới
3. Sau khi đăng ký → Đăng nhập
4. Xem danh sách phim
5. Chọn phim → Xem suất chiếu
6. Chọn suất chiếu → Chọn ghế
7. Đặt vé → Xem chi tiết vé với QR code

### Test flow Staff:
1. Đăng nhập với tài khoản staff
2. Xem dashboard thống kê
3. Test các chức năng bán vé, soát vé

## 🐛 XỬ LÝ LỖI THƯỜNG GẶP

### Lỗi 1: Không kết nối được API
**Nguyên nhân:** 
- Sai IP/URL
- Server chưa chạy
- Firewall block

**Giải pháp:**
- Kiểm tra lại baseUrl trong api_constants.dart
- Ping IP server từ thiết bị: `ping YOUR_SERVER_IP`
- Test API bằng browser trên thiết bị

### Lỗi 2: HTTPS Certificate Error
**Nguyên nhân:**
- Sử dụng certificate tự ký (self-signed)
- Certificate không được tin cậy
- Network security config chưa đúng

**Giải pháp:**
- Đảm bảo backend có SSL certificate hợp lệ
- Hoặc cập nhật network_security_config.xml để cho phép certificate tự ký
- Test API bằng browser trước: `https://localhost:44300/api/auth/login`

### Lỗi 3: CORS Error
**Giải pháp:** Thêm CORS config trong Web.config hoặc Global.asax:
```csharp
protected void Application_BeginRequest()
{
    if (Request.Headers.AllKeys.Contains("Origin"))
    {
        Response.AddHeader("Access-Control-Allow-Origin", "*");
        Response.AddHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        Response.AddHeader("Access-Control-Allow-Headers", "Content-Type, Accept");
        
        if (Request.HttpMethod == "OPTIONS")
        {
            Response.StatusCode = 200;
            Response.End();
        }
    }
}
```

### Lỗi 4: Build failed
```bash
flutter clean
flutter pub get
flutter run
```

### Lỗi 4: Dependencies conflict
```bash
flutter pub upgrade
```

## 📦 BUILD ỨNG DỤNG

### Build APK (Android):
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK theo ABI (giảm kích thước)
flutter build apk --split-per-abi
```

File APK sẽ nằm ở: `build/app/outputs/flutter-apk/`

### Build App Bundle (Android):
```bash
flutter build appbundle
```

### Build iOS:
```bash
flutter build ios --release
```

## 🎯 KIỂM TRA CHẤT LƯỢNG CODE

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Run tests (nếu có)
flutter test
```

## 📊 CẤU TRÚC DATABASE CẦN THIẾT

Đảm bảo database có các bảng:
- Khach_Hang (customers)
- Nhan_Vien (staff/employees)
- Phim (movies)
- Suat_Chieu (showtimes)
- Ghe (seats)
- Dat_Ve (bookings)
- Ve (tickets)

## 🔒 BẢO MẬT

### 1. Không hardcode sensitive data
### 2. Sử dụng HTTPS cho production
### 3. Mã hóa local storage
### 4. Validate input phía client và server

## 📱 TEST TRÊN NHIỀU THIẾT BỊ

### Screen sizes cần test:
- Small phone (5" - 5.5")
- Medium phone (6" - 6.5")
- Large phone/Tablet (7"+)

### Android versions:
- Android 8.0 (API 26) trở lên

### iOS versions:
- iOS 12 trở lên

## 🚀 DEPLOY LÊN STORE

### Google Play Store:
1. Tạo keystore
2. Cấu hình signing trong android/app/build.gradle
3. Build app bundle
4. Upload lên Play Console

### Apple App Store:
1. Cấu hình certificates & provisioning profiles
2. Build release iOS
3. Upload qua Xcode hoặc Transporter

## 📞 HỖ TRỢ

Nếu gặp vấn đề:
1. Kiểm tra logs: `flutter logs`
2. Xem lỗi trong VS Code
3. Google error message
4. Stack Overflow

## ✅ CHECKLIST TRƯỚC KHI DEPLOY

- [ ] Backend hỗ trợ HTTPS với SSL certificate hợp lệ
- [ ] API URL đã đúng (https://localhost:44300)
- [ ] Test tất cả flows (login, register, booking)
- [ ] UI responsive trên nhiều màn hình
- [ ] Xử lý loading states
- [ ] Xử lý error states
- [ ] Offline handling (nếu có)
- [ ] App icon đã đổi
- [ ] App name đã đổi
- [ ] Version number đã update
- [ ] Build release thành công

## 🎉 HOÀN THÀNH

Chúc bạn triển khai thành công ứng dụng Cinema App!
