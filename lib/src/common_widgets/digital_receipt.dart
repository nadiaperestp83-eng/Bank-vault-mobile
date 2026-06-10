import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/models/receipt_model.dart';
import 'package:vault_os/src/utils/currency_formatter.dart';

class DigitalReceipt extends StatelessWidget {
  final VaultReceipt receipt;

  const DigitalReceipt({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Receipt Paper
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo or Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.landmark, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'VAULT RECEIPT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                // Amount
                Text(
                  CurrencyFormatter.format(receipt.amount, receipt.currency),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  receipt.transactionDetails['type']?.toString().toUpperCase() ?? 'TRANSACTION',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                // Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildDetailRow('Receipt Number', receipt.receiptNumber, theme),
                      const Divider(height: 24),
                      _buildDetailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(receipt.createdAt), theme),
                      const Divider(height: 24),
                      _buildDetailRow('Payment Method', receipt.transactionDetails['method']?.toString().toUpperCase() ?? 'WALLET', theme),
                      const Divider(height: 24),
                      _buildDetailRow('Status', 'COMPLETED', theme, valueColor: AppColors.success),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Certified Stamp
                Transform.rotate(
                  angle: -0.1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CERTIFIED BY VAULT',
                      style: TextStyle(
                        color: AppColors.success.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Dashed Cut Line
                CustomPaint(
                  size: const Size(double.infinity, 20),
                  painter: DashPainter(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateAndPrintPdf(receipt),
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 18),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndPrintPdf(VaultReceipt receipt) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('VAULT OS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('OFFICIAL RECEIPT', style: pw.TextStyle(fontSize: 10, letterSpacing: 2)),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                CurrencyFormatter.format(receipt.amount, receipt.currency),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _buildPdfRow('Receipt #', receipt.receiptNumber),
              _buildPdfRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(receipt.createdAt)),
              _buildPdfRow('Method', receipt.transactionDetails['method']?.toString().toUpperCase() ?? 'WALLET'),
              _buildPdfRow('Type', receipt.transactionDetails['type']?.toString().toUpperCase() ?? 'TRANSACTION'),
              pw.SizedBox(height: 20),
              pw.Text('CERTIFIED BY VAULT', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 8)),
              pw.SizedBox(height: 10),
              pw.BarcodeWidget(
                data: receipt.receiptNumber,
                barcode: pw.Barcode.code128(),
                width: 100,
                height: 40,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}

class DashPainter extends CustomPainter {
  final Color color;

  DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    var max = size.width;
    var dashWidth = 8;
    var dashSpace = 4;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }

    // Semi-circles for the "cut" effect at the bottom
    var circlePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    double circleX = 0;
    double radius = 6;
    while (circleX < max) {
      canvas.drawCircle(Offset(circleX, 10), radius, circlePaint);
      circleX += radius * 3;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
