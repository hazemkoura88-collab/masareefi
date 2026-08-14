import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;
import 'database_helper.dart';

class ExportHelper {
  static Future<String> exportToExcel(List<Expense> expenses) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Ù…ØµØ§Ø±ÙŠÙÙŠ'];
    excel.setDefaultSheet('Ù…ØµØ§Ø±ÙŠÙÙŠ');

    sheetObject.appendRow([
      TextCellValue('Ø§Ù„Ø±Ù‚Ù…'),
      TextCellValue('Ø§Ù„ØªØ§Ø¬Ø±'),
      TextCellValue('Ø§Ù„Ù…Ø¨Ù„Øº (SAR)'),
      TextCellValue('Ø§Ù„ØªØµÙ†ÙŠÙ'),
      TextCellValue('Ù†ÙˆØ¹ Ø§Ù„Ø¹Ù…Ù„ÙŠØ©'),
      TextCellValue('Ø¢Ø®Ø± 4 Ø£Ø±Ù‚Ø§Ù…'),
      TextCellValue('Ø§Ù„ØªØ§Ø±ÙŠØ® ÙˆØ§Ù„ÙˆÙ‚Øª'),
    ]);

    for (var exp in expenses) {
      sheetObject.appendRow([
        IntCellValue(exp.id ?? 0),
        TextCellValue(exp.merchant),
        DoubleCellValue(exp.amount),
        TextCellValue(exp.category),
        TextCellValue(exp.type),
        TextCellValue(exp.cardLast4),
        TextCellValue(intl.DateFormat('yyyy-MM-dd HH:mm').format(exp.date)),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    String path = "/masareefi_export_.xlsx";
    var fileBytes = excel.save();
    
    if (fileBytes != null) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }
    return path;
  }

  static Future<void> exportToPdf(List<Expense> expenses) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    double totalAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ØªÙ‚Ø±ÙŠØ± Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª - ØªØ·Ø¨ÙŠÙ‚ Ù…ØµØ§Ø±ÙŠÙÙŠ', style: pw.TextStyle(font: fontBold, fontSize: 18)),
                    pw.Text(intl.DateFormat('yyyy/MM/dd').format(DateTime.now()), style: pw.TextStyle(font: font, fontSize: 12)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª:  Ø±.Ø³', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.teal)),
              pw.SizedBox(height: 15),
              
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Ø§Ù„ØªØ§Ø¬Ø±', 'Ø§Ù„Ù…Ø¨Ù„Øº', 'Ø§Ù„ØªØµÙ†ÙŠÙ', 'Ø§Ù„ØªØ§Ø±ÙŠØ®'],
                data: expenses.map((e) => [
                  e.merchant,
                  ' Ø±.Ø³',
                  e.category,
                  intl.DateFormat('yyyy/MM/dd').format(e.date),
                ]).toList(),
                headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellStyle: pw.TextStyle(font: font),
                cellAlignment: pw.Alignment.centerRight,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}