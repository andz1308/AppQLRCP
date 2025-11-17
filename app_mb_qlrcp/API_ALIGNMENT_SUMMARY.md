# DAV Cinema Mobile App - API Alignment & Branding Update

## ✅ Completed Tasks

### 1. DAV Branding Implementation
All screens now display the DAV logo and branding:

- **Splash Screen** (`lib/main.dart`): Large "DAV" text (64px bold) with subtitle "Rạp Chiếu Phim Hàng Đầu Việt Nam"
- **Login Screen** (`lib/screens/login_screen.dart`): "DAV" logo (56px) with "Chào mừng quay trở lại"
- **Register Screen** (`lib/screens/register_screen.dart`): "DAV" logo (48px) with "Tạo tài khoản DAV"
- **Customer Home** (`lib/screens/customer/customer_home_screen.dart`): AppBar "DAV Cinema" with orange theme
- **Staff Dashboard** (`lib/screens/staff/staff_home_screen.dart`): AppBar "DAV - Bảng Điều Khiển" with orange theme

### 2. API Alignment
✅ **All API endpoints are correctly implemented and match the backend:**

#### Authentication (API Base: `https://10.0.2.2:44300/api/auth`)
- `POST /login` - Request: `{email, password}` → Response: `{success, message, user: {user_id, name, email, phone, role}}`
- `POST /register` - Request: `{name, email, password, phone}` → Response: `{success, message}`

#### Customer Endpoints (API Base: `https://10.0.2.2:44300/api/customer`)
- `GET /movies?page=1&pageSize=10` - Returns: `{success, message, data: {movies[], total, current_page, total_pages, page_size}}`
- `GET /showtimes/{movieId}` - Returns: `{success, message, data: [showtime objects]}`
- `GET /bookings/{customerId}` - Returns: `{success, message, data: [booking objects]}`
- `GET /seats/{showtimeId}` - Returns: `{success, message, data: [seat objects]}`
- `POST /create-booking` - Request: `{customer_id, showtime_id, seat_ids, foods}` → Response: `{success, message, booking_id}`

#### Staff Endpoints (API Base: `https://10.0.2.2:44300/api/staff`)
- `GET /dashboard/{staffId}` - Returns: `{success, message, data: dashboard stats}`
- `GET /showtimes?date=YYYY-MM-DD` - Returns: `{success, message, data: [showtimes]}`
- `GET /seats/{showtimeId}` - Returns: `{success, message, data: [seats]}`
- `POST /create-booking` - Offline booking for staff
- `POST /verify-ticket` - QR code verification

### 3. Request Headers Configuration
✅ **Host header properly set for emulator-to-host communication:**
- Added `lib/utils/request_headers.dart` with `jsonHeaders()` helper
- All HTTP requests include:
  - `Content-Type: application/json`
  - `Host: localhost:44300` (fixes "Invalid Hostname" 400 errors)
- Used in `AuthService`, `BookingService`, `MovieService`, `StaffService`

### 4. HTTPS Certificate Handling
✅ **Development-only self-signed certificate support:**
- Added `lib/utils/http_overrides.dart` for accepting dev certificates
- Enabled in `lib/main.dart` before runApp()
- Allows secure connection to `https://10.0.2.2:44300` from emulator

## 📋 API Response Format Notes

All API responses follow the standard format:
```json
{
  "success": true/false,
  "message": "Vietnamese message",
  "data": { /* endpoint-specific data */ }
}
```

## 🎯 Next Steps (Optional Enhancements)

1. **Staff Features**:
   - Complete staff offline booking UI
   - QR code scanning and verification flow

2. **Features from Web API**:
   - Profile updates (if available)
   - Booking cancellation
   - Payment status tracking
   - Cinema location details

3. **UI Polish**:
   - Add DAV logo as image asset (optional PNG variant)
   - Improve dark mode support
   - Add animations for DAV branding

4. **Production Checklist**:
   - Remove HttpOverrides when deploying (only for debug)
   - Update baseUrl to production API endpoint
   - Remove debug print statements
   - Test on physical Android/iOS devices

## 🚀 Running the App

```bash
cd d:\APPMBQLRCP\app_mb_qlrcp
flutter run -d emulator-5554
```

**Test Credentials** (from web):
- Email: `leminh@example.com`
- Password: `admin123`

---

**Status**: ✅ Ready for testing with updated API endpoint
