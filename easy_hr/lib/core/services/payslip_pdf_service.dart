import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PayslipPdfService {
  static Future<void> generateAndPreview(Map<String, dynamic> payslip, int year, int month) async {
    final pdf = _buildPdf(payslip, year, month);
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static Future<void> sharePdf(Map<String, dynamic> payslip, int year, int month) async {
    final pdf = _buildPdf(payslip, year, month);
    final bytes = await pdf.save();
    final monthName = DateFormat('MMMM_yyyy').format(DateTime(year, month));
    await Printing.sharePdf(bytes: bytes, filename: 'Payslip_$monthName.pdf');
  }

  static pw.Document _buildPdf(Map<String, dynamic> payslip, int year, int month) {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    // Extract data
    final gross = ((payslip['gross_salary'] ?? 0) as num).toDouble();
    final net = ((payslip['net_salary'] ?? 0) as num).toDouble();
    final base = ((payslip['basic_salary'] ?? 0) as num).toDouble();
    final allowances = ((payslip['total_allowances'] ?? 0) as num).toDouble();
    final deductions = ((payslip['total_deductions'] ?? 0) as num).toDouble();
    final ot = ((payslip['ot_amount'] ?? payslip['overtime_pay'] ?? 0) as num).toDouble();
    final tax = ((payslip['tax_amount'] ?? payslip['tax'] ?? 0) as num).toDouble();
    final ssb = ((payslip['ssb_amount'] ?? 0) as num).toDouble();
    final advance = ((payslip['advance_deduction'] ?? 0) as num).toDouble();
    final bonus = ((payslip['bonus'] ?? payslip['attendance_bonus'] ?? 0) as num).toDouble();
    final daysPresent = payslip['days_present'] ?? 0;
    final daysAbsent = payslip['days_absent'] ?? 0;
    final daysLate = payslip['days_late'] ?? 0;
    final totalWorkingDays = payslip['total_working_days'] ?? 0;
    final status = payslip['status'] ?? 'calculated';

    // Employee info
    final emp = payslip['employee'] is Map ? payslip['employee'] as Map : {};
    final empName = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    final empCode = emp['employee_code'] ?? '';
    final empPhone = emp['phone'] ?? '';
    final empEmail = emp['email'] ?? '';
    final empNrc = emp['nrc_number'] ?? '';
    final dept = emp['department'] is Map ? emp['department']['name'] ?? '' : '';
    final position = emp['position'] is Map ? emp['position']['title'] ?? '' : '';

    // Company info
    final company = emp['company'] is Map ? emp['company'] as Map : {};
    final companyName = company['name'] ?? 'Easy HR';
    final companyAddress = company['address'] ?? '';
    final companyPhone = company['phone'] ?? '';
    final companyEmail = company['email'] ?? '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2563EB'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(companyName.toString(),
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if (companyAddress.isNotEmpty)
                      pw.Text(companyAddress.toString(), style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Text('PAYSLIP - $monthName',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Employee Info
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow('Employee Name', empName.isEmpty ? 'N/A' : empName),
                          _infoRow('Employee Code', empCode.isEmpty ? 'N/A' : empCode.toString()),
                          _infoRow('Department', dept.isEmpty ? 'N/A' : dept.toString()),
                          _infoRow('Position', position.isEmpty ? 'N/A' : position.toString()),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow('Phone', empPhone.isEmpty ? 'N/A' : empPhone.toString()),
                          _infoRow('NRC', empNrc.isEmpty ? 'N/A' : empNrc.toString()),
                          _infoRow('Pay Period', monthName),
                          _infoRow('Status', status.toString().toUpperCase()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Attendance Summary
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0F9FF'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _attendanceItem('Working Days', '$totalWorkingDays'),
                    _attendanceItem('Present', '$daysPresent'),
                    _attendanceItem('Absent', '$daysAbsent'),
                    _attendanceItem('Late', '$daysLate'),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Earnings & Deductions Table
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          color: PdfColor.fromHex('#10B981'),
                          child: pw.Text('EARNINGS', style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ),
                        _tableRow('Base Salary', _fmt(base)),
                        _tableRow('Allowances', _fmt(allowances)),
                        _tableRow('Overtime Pay', _fmt(ot)),
                        if (bonus > 0) _tableRow('Bonus', _fmt(bonus)),
                        pw.Divider(thickness: 0.5),
                        _tableRow('Gross Salary', _fmt(gross), bold: true),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Deductions
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          color: PdfColor.fromHex('#EF4444'),
                          child: pw.Text('DEDUCTIONS', style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ),
                        _tableRow('SSB (2%)', _fmt(ssb)),
                        _tableRow('Income Tax', _fmt(tax)),
                        if (advance > 0) _tableRow('Salary Advance', _fmt(advance)),
                        pw.Divider(thickness: 0.5),
                        _tableRow('Total Deductions', _fmt(deductions), bold: true),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Net Salary
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2563EB'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET SALARY (Take Home)',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(_fmt(net),
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Easy HR', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
                  pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('This is a computer-generated payslip and does not require a signature.',
                  style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text('$label:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _attendanceItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _tableRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static String _fmt(double amount) {
    return '${NumberFormat('#,###').format(amount.round())} MMK';
  }
}
