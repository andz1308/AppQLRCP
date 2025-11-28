# 🚀 Rebuild API với VNPay Fix

## Những gì vừa sửa

**Sửa endpoint `POST /api/customer/get-vnpay-payment-url`**
- ❌ Cũ: Gọi `Infrastructure.PaymentGateway` (class không tồn tại) → Error 500
- ✅ Mới: Tự tạo VNPay payment URL trực tiếp với:
  - HMAC SHA512 hash calculation (chính xác theo VNPay spec)
  - SortedDictionary để đảm bảo thứ tự parameter
  - Tất cả required parameters: vnp_Version, vnp_Command, vnp_TmnCode, vnp_Amount, vnp_CreateDate, vnp_CurrCode, vnp_ExpireDate, vnp_IpAddr, vnp_IpnUrl, vnp_Locale, vnp_OrderInfo, vnp_OrderType, vnp_ReturnUrl, vnp_TxnRef
  - VNPay credentials: TMN Code + Hash Secret được hardcoded (TODO: move to Web.config)

## Helper Methods Thêm Vào

1. **ComputeHmacSha512** - Tính hash SHA512 cho VNPay
2. **GetClientIpAddress** - Lấy IP client

## Rebuild Steps

### 1. Mở Visual Studio
- Mở Solution WebCinema API

### 2. Clean & Rebuild
```
Build → Clean Solution
Build → Rebuild Solution
```

### 3. Publish to IIS
- Publish bằng Visual Studio hoặc copy DLL compiled sang folder IIS

### 4. Restart IIS
```powershell
# Run as Administrator
iisreset /restart
```

## Test Endpoint

Sau khi rebuild, test bằng Postman:

```
POST https://10.0.2.2:44300/api/customer/get-vnpay-payment-url
Authorization: Bearer YOUR_AUTH_TOKEN
Content-Type: application/json

{
  "booking_id": 173
}
```

### Expected Response (Success):
```json
{
  "success": true,
  "message": "Lấy URL thanh toán VNPay thành công",
  "data": {
    "payment_url": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Version=2.1.0&vnp_Command=pay&vnp_TmnCode=NJJ0R8FS&vnp_Amount=8200000&...",
    "amount": 82000,
    "customer_email": "customer@example.com",
    "customer_name": "Nguyễn Văn A",
    "booking_id": 173
  }
}
```

### Nếu vẫn lỗi:
- Kiểm tra booking ID có tồn tại không
- Kiểm tra booking status có phải "Chưa thanh toán" không
- Kiểm tra VNPay credentials đúng không

## Expected Flow

1. ✅ Flutter app gọi `/api/customer/get-vnpay-payment-url`
2. ✅ API tạo VNPay payment URL (với HMAC hash đúng)
3. ✅ Flutter nhận URL và mở WebView
4. ✅ User thấy trang VNPay thanh toán (NO ERROR 99!)
5. ✅ User thanh toán → VNPay redirect về app
6. ✅ App gọi `/api/customer/process-vnpay-payment`
7. ✅ Booking chuyển thành "Đã Thanh toán"
8. ✅ Email hóa đơn được gửi

## Next Steps

- ⏳ Rebuild API
- ⏳ Deploy to IIS
- ⏳ Restart IIS
- ⏳ Test endpoint in Postman (should return URL, not error!)
- ⏳ Run Flutter app - should see VNPay payment page

---

**Status**: Code fixed, waiting for rebuild & deploy
