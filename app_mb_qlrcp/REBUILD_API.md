# 🔨 Rebuild API với Khuyến Mãi

## Những gì vừa thêm vào API

Thêm 3 endpoint mới để xử lý khuyến mãi:

### 1. POST `/api/customer/check-promo`
- Kiểm tra mã khuyến mãi có hợp lệ không
- Trả về: % giảm giá, ngày hết hạn, mô tả

### 2. POST `/api/customer/available-promos`
- Lấy danh sách tất cả khuyến mãi có sẵn cho khách hàng
- Chỉ trả về những khuyến mãi đang Active và chưa hết hạn

### 3. POST `/api/customer/booking/{bookingId}/apply-promo`
- Áp dụng mã khuyến mãi vào đơn đặt vé
- Cập nhật tổng tiền sau giảm giá

## Yêu Cầu Model Database

Phải có bảng `Khuyen_Mai` với ít nhất các field sau:
- `ma_khuyen` (string) - Mã khuyến mãi
- `mo_ta` (string) - Mô tả
- `phan_tram_giam` (decimal) - % giảm giá
- `ngay_bat_dau` (datetime) - Ngày bắt đầu
- `ngay_ket_thuc` (datetime) - Ngày kết thúc
- `trang_thai` (string) - "Active" hoặc "Inactive"

Bảng `Dat_Ve` cần thêm field:
- `ma_khuyen` (string) - Mã khuyến mãi đã áp dụng

## Rebuild API

### Bước 1: Mở Visual Studio
- Mở Solution của API

### Bước 2: Build Solution
```
Build → Clean Solution
Build → Rebuild Solution
```

### Bước 3: Publish/Deploy
- Publish API lên IIS
- Hoặc copy DLL compile được vào thư mục IIS

### Bước 4: Restart IIS
```powershell
# Run as Administrator
iisreset /restart
```

## Test Endpoint

Sau khi rebuild và restart IIS, test bằng Postman:

### Test 1: Get Available Promos
```
POST https://10.0.2.2:44300/api/customer/available-promos
Header: Authorization: Bearer YOUR_TOKEN
Body: { "customer_id": 24 }
```

Expected Response:
```json
{
  "success": true,
  "message": "Có 3 mã khuyến mãi có sẵn",
  "data": [
    {
      "maKhuyen": "SALE20",
      "moTa": "Giảm 20%",
      "phanTramGiam": 20,
      "ngayBatDau": "2025-11-01",
      "ngayKetThuc": "2025-12-31",
      "isApplicable": true,
      "reason": ""
    }
  ]
}
```

### Test 2: Check Promo
```
POST https://10.0.2.2:44300/api/customer/check-promo
Header: Authorization: Bearer YOUR_TOKEN
Body: { "promo_code": "SALE20", "food_items": [] }
```

### Test 3: Apply Promo
```
POST https://10.0.2.2:44300/api/customer/booking/1/apply-promo
Header: Authorization: Bearer YOUR_TOKEN
Body: { "promo_code": "SALE20", "original_total": 150000 }
```

## Lưu ý

- API files đã được update với 3 endpoint mới
- Cần rebuild DLL để thay đổi có hiệu lực
- Flutter app đã sẵn sàng gọi các endpoint này (không cần sửa gì)

## Status

✅ API code added  
⏳ Waiting for rebuild & deploy  
⏳ Waiting for IIS restart  
⏳ Waiting for test  
