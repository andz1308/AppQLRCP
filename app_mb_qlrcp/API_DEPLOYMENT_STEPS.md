# 🔧 API Deployment Steps - VNPay Integration

## Problem
The Flutter app is getting **HTTP 404** when calling `/api/customer/get-vnpay-payment-url`

Error:
```
I/flutter ( 5629): ❌ Lấy VNPay URL thất bại: Error: DioException [bad response]: This exception was thrown because the response has a status code of 404
```

## Root Cause
✅ The endpoint code exists in `API/CustomerApiController.cs` (lines 1406-1501)  
❌ But the API **DLL has NOT been recompiled** with the new endpoint

## Solution: Rebuild and Deploy API

### Option 1: Rebuild in Visual Studio (Recommended)

1. **Open the API solution** in Visual Studio
   - Find the solution file (`.sln`) for the Web Cinema API
   - It should be in a parent folder or a different location from this Flutter project

2. **Build the solution**
   ```
   Build → Rebuild Solution
   ```

3. **Deploy/Publish**
   - Publish to IIS using your existing deployment method
   - Or copy the compiled DLL to your IIS application folder

4. **Restart IIS**
   ```powershell
   # Run as Administrator
   iisreset
   ```

### Option 2: Using Command Line (.NET Framework)

If it's a .NET Framework project:

```powershell
# Build the API project
cd "C:\path\to\WebCinema\API"
msbuild WebCinema.csproj /p:Configuration=Release

# Or if using .NET CLI (for .NET Core/5+)
cd "C:\path\to\WebCinema"
dotnet build
dotnet publish -c Release
```

### Option 3: IIS Application Pool Restart

If you just deployed but still getting 404:

```powershell
# Run as Administrator
# Restart the application pool
iisreset /restart

# Or restart specific app pool
Stop-WebAppPool -Name "YourAppPoolName"
Start-WebAppPool -Name "YourAppPoolName"
```

## Verification

After redeployment, test the endpoint:

```bash
# Using Postman or curl
POST https://10.0.2.2:44300/api/customer/get-vnpay-payment-url
Header: Authorization: Bearer YOUR_TOKEN
Body: { "booking_id": 1 }
```

Expected successful response:
```json
{
  "success": true,
  "message": "Lấy URL thanh toán VNPay thành công",
  "data": {
    "payment_url": "https://sandbox.vnpayment.vn/...",
    "order_id": "1_637123456789",
    "amount": 150000,
    ...
  }
}
```

## Files Modified
- `API/CustomerApiController.cs` - Added `GetVNPayPaymentUrl()` endpoint (lines 1406-1501)

## Next Steps After API Redeployment
1. ✅ Rebuild API and deploy
2. ✅ Restart IIS
3. ✅ Test endpoint in Postman
4. ✅ Run Flutter app again - should see VNPay payment page

---
**Status**: Waiting for API redeployment ⏳
