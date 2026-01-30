import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class PrinterService {
  /// Imprime una factura
  Future<void> printInvoice(Map<String, dynamic> invoiceData, String invoiceNumber) async {
    try {
      final pdf = await _generateInvoicePdf(invoiceData, invoiceNumber);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      print('Error al imprimir: $e');
      throw Exception('Error al conectar con la impresora: $e');
    }
  }

  /// Genera el PDF de la factura en formato POS (80mm)
  Future<pw.Document> _generateInvoicePdf(
    Map<String, dynamic> invoiceData,
    String invoiceNumber,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    // 80mm width is approx 226 points at 72 dpi (80mm / 25.4 * 72)
    // We use a continuous page format (roll)
    const pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm, 
      double.infinity, 
      marginAll: 5 * PdfPageFormat.mm
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'MOTOLINE',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Sistema de Facturación', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('NIT: 900.123.456-7', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Tel: (601) 123-4567', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 8),
                  ],
                ),
              ),
              
              pw.Divider(thickness: 0.5),
              
              // Invoice Info & Customer
              pw.Text(
                invoiceData['isElectronic'] ? 'FACTURA ELECTRÓNICA' : 'FACTURA',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('No. $invoiceNumber', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Fecha: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 10)),
              
              pw.SizedBox(height: 8),
              pw.Text('CLIENTE:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('${invoiceData['customerName']}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('CC/NIT: ${invoiceData['customerId']}', style: const pw.TextStyle(fontSize: 10)),
              
              pw.Divider(thickness: 0.5),
              
              // Items (Simplified for POS)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Desc', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Cant x Precio', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              
              ...List.generate(
                invoiceData['items'].length,
                (index) {
                  final item = invoiceData['items'][index];
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item['productName'],
                        style: const pw.TextStyle(fontSize: 10),
                        maxLines: 2,
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '', // Spacer/Indentation for second line
                          ),
                          pw.Text(
                            '${item['quantity']} x \$${item['price'].toStringAsFixed(0)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            '\$${item['subtotal'].toStringAsFixed(0)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                    ],
                  );
                },
              ),
              
              pw.Divider(thickness: 0.5),
              
              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: \$${invoiceData['total'].toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                    if (invoiceData['discount'] > 0)
                      pw.Text(
                        'Desc (${invoiceData['discount']}%): -\$${(invoiceData['total'] * invoiceData['discount'] / 100).toStringAsFixed(0)}',
                         style: const pw.TextStyle(fontSize: 10),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'TOTAL: \$${invoiceData['totalWithDiscount'].toStringAsFixed(0)}',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Metodo de pago:', style: const pw.TextStyle(fontSize: 10)),
                   pw.Text('${invoiceData['paymentMethod'] ?? 'Efectivo'}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              
              pw.SizedBox(height: 16),
              
              // Footer
              pw.Center(
                child: pw.Text(
                  'Gracias por su compra',
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ),
              if (invoiceData['isElectronic']) ...[
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Rep. gráfica factura electrónica',
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
              pw.SizedBox(height: 20), // Bottom padding for cut
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Verifica si hay impresoras disponibles
  Future<bool> hasAvailablePrinters() async {
    try {
      final printers = await Printing.listPrinters();
      return printers.isNotEmpty;
    } catch (e) {
      print('Error al listar impresoras: $e');
      return false;
    }
  }

  /// Obtiene la lista de impresoras disponibles
  Future<List<String>> getAvailablePrinters() async {
    try {
      final printers = await Printing.listPrinters();
      return printers.map((p) => p.name).toList();
    } catch (e) {
      print('Error al obtener impresoras: $e');
      return [];
    }
  }
}