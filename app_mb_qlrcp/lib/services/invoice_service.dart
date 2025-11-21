import 'dart:io';
// ignore: unused_import
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InvoiceService {
  /// Tạo QR code từ chuỗi dữ liệu và lưu vào thư mục
  static Future<String?> generateAndSaveQRCode(
    String data, {
    required String filename,
  }) async {
    try {
      // Tạo QR code image
      final qrImage = await QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
      ).toImageData(200);

      if (qrImage == null) {
        print('❌ Không thể tạo QR code image');
        return null;
      }

      // Lấy thư mục lưu QR
      final Directory appDir = Directory('D:/APPMBQLRCP/app_mb_qlrcp/img/qr');
      if (!appDir.existsSync()) {
        appDir.createSync(recursive: true);
      }

      final bytes = qrImage.buffer.asUint8List();
      final File qrFile = File('${appDir.path}/$filename.png');
      await qrFile.writeAsBytes(bytes);

      print('✅ QR code saved: ${qrFile.path}');
      return qrFile.path;
    } catch (e) {
      print('❌ Error generating QR: $e');
      return null;
    }
  }

  /// Lấy hoặc tạo QR code cho một ticket
  static Future<String?> getOrCreateQRForTicket(
    Map<String, dynamic> ticket,
  ) async {
    try {
      final ticketId = ticket['ticket_id']?.toString();
      final qrCodeFromAPI = ticket['qr_code']?.toString();

      // Nếu API đã cung cấp QR code, trả về ngay
      if (qrCodeFromAPI != null &&
          qrCodeFromAPI.isNotEmpty &&
          qrCodeFromAPI != 'N/A') {
        print('✅ Using QR from API for ticket $ticketId');
        return qrCodeFromAPI;
      }

      // Nếu không có QR từ API, tạo từ ticket ID
      if (ticketId != null && ticketId.isNotEmpty) {
        final qrPath = await generateAndSaveQRCode(
          ticketId,
          filename: 'ticket_$ticketId',
        );
        return qrPath;
      }

      print('⚠️ No ticket ID to generate QR');
      return null;
    } catch (e) {
      print('❌ Error getting/creating QR: $e');
      return null;
    }
  }

  /// Tạo QR code image bytes để embed trong PDF
  static Future<Uint8List?> generateQRImageBytes(String data) async {
    try {
      final qrImage = await QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
      ).toImageData(150);

      if (qrImage == null) {
        print('❌ Không thể tạo QR code image');
        return null;
      }

      return qrImage.buffer.asUint8List();
    } catch (e) {
      print('❌ Error generating QR image bytes: $e');
      return null;
    }
  }

  /// Tạo PDF hóa đơn từ dữ liệu booking với QR code images
  static Future<void> generateAndSaveInvoicePDF(
    Map<String, dynamic> booking,
  ) async {
    try {
      final pdf = pw.Document();

      // Parse data
      final bookingId = booking['booking_id']?.toString() ?? 'N/A';
      final customerName = booking['customer_name']?.toString() ?? 'N/A';
      final customerEmail = booking['customer_email']?.toString() ?? 'N/A';
      final customerPhone = booking['customer_phone']?.toString() ?? 'N/A';
      final createdAt = booking['created_at']?.toString() ?? 'N/A';
      final totalAmount = booking['total_amount']?.toString() ?? '0';
      final movieTitle = booking['movie']?['title']?.toString() ?? 'N/A';
      final cinema = booking['showtime']?['cinema']?.toString() ?? 'N/A';
      final room = booking['showtime']?['room']?.toString() ?? 'N/A';
      final date = booking['showtime']?['date']?.toString() ?? 'N/A';
      final time = booking['showtime']?['time']?.toString() ?? 'N/A';
      final tickets = booking['tickets'] as List? ?? [];

      // Generate QR images for each ticket
      final ticketQRImages = <String, Uint8List?>{};
      for (final ticket in tickets) {
        final qrCode = ticket['qr_code']?.toString() ?? '';
        if (qrCode.isNotEmpty) {
          ticketQRImages[qrCode] = await generateQRImageBytes(qrCode);
        }
      }

      // Tạo page PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'HÓA ĐƠN THANH TOÁN',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'ĐƠN ĐẶT VÉ XEM PHIM',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Mã đơn: $bookingId'),
                      pw.Text('Ngày: $createdAt'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Thông tin khách hàng',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Tên: $customerName'),
                pw.Text('Email: $customerEmail'),
                pw.Text('Điện thoại: $customerPhone'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Thông tin suất chiếu',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Phim: $movieTitle'),
                pw.Text('Rạp: $cinema'),
                pw.Text('Phòng: $room'),
                pw.Text('Ngày chiếu: $date - $time'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Thông tin vé',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Ghế',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Mã QR',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Giá',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...tickets.map((ticket) {
                  final seatNumber = ticket['seat_number']?.toString() ?? 'N/A';
                  final qrCode = ticket['qr_code']?.toString() ?? 'N/A';
                  final price = ticket['price']?.toString() ?? '0';
                  final qrImageBytes = ticketQRImages[qrCode];

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(seatNumber),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: qrImageBytes != null
                            ? pw.Image(
                                pw.MemoryImage(qrImageBytes),
                                width: 60,
                                height: 60,
                              )
                            : pw.Text(
                                qrCode.length > 20
                                    ? '${qrCode.substring(0, 20)}...'
                                    : qrCode,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('$price đ'),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Tổng cộng: $totalAmount đ',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Cảm ơn bạn đã mua vé!',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      );

      // Lưu PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/Invoice_$bookingId.pdf');
      await file.writeAsBytes(await pdf.save());

      print('✅ Invoice PDF saved: ${file.path}');
    } catch (e) {
      print('❌ Error generating invoice PDF: $e');
    }
  }

  /// Mở PDF để xem/in
  static Future<void> openInvoicePDF(String bookingId) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/Invoice_$bookingId.pdf');

      if (file.existsSync()) {
        await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: 'Invoice_$bookingId.pdf',
        );
      } else {
        print('❌ File not found: ${file.path}');
      }
    } catch (e) {
      print('❌ Error opening invoice PDF: $e');
    }
  }
}
