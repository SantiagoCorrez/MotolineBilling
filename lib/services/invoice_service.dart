import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InvoiceService {
  static const String baseUrl = 'https://motolineparts.com/api';
  final AuthService _authService = AuthService();

  /// Genera una factura electrónica con la DIAN
  Future<String> generateElectronicInvoice(Map<String, dynamic> invoiceData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/electronic'),
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['invoiceNumber'] ?? _generateMockInvoiceNumber();
      }
      throw Exception('Error al generar factura electrónica');
    } catch (e) {
      print('Error en generateElectronicInvoice: $e');
      // En desarrollo, retorna un número de factura simulado
      return _generateMockInvoiceNumber();
    }
  }

  /// Genera una factura normal (no electrónica)
  Future<String> generateNormalInvoice(Map<String, dynamic> invoiceData) async {
    try {

      final response = await http.post(
        Uri.parse('$baseUrl/invoices/normal'),
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['invoiceNumber'] ?? _generateMockInvoiceNumber();
      }
      throw Exception('Error al generar factura');
    } catch (e) {
      print('Error en generateNormalInvoice: $e');
      return _generateMockInvoiceNumber();
    }
  }

  /// Obtiene el historial de facturas
  Future<List<Map<String, dynamic>>> getInvoiceHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices'),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      print('Error en getInvoiceHistory: $e');
      return [];
    }
  }

  /// Obtiene los detalles de una factura específica
  Future<Map<String, dynamic>?> getInvoiceDetails(String invoiceNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/$invoiceNumber'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error en getInvoiceDetails: $e');
      return null;
    }
  }

  /// Genera un número de factura simulado para desarrollo
  String _generateMockInvoiceNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'INV-${timestamp.toString().substring(7)}';
  }

  /// Valida el formato de una cédula colombiana
  bool validateCedula(String cedula) {
    // Elimina espacios y guiones
    cedula = cedula.replaceAll(RegExp(r'[\s-]'), '');
    
    // Debe tener entre 6 y 10 dígitos
    if (cedula.length < 6 || cedula.length > 10) {
      return false;
    }
    
    // Debe contener solo números
    return RegExp(r'^\d+$').hasMatch(cedula);
  }

  /// Valida el formato de un NIT colombiano
  bool validateNit(String nit) {
    // Elimina espacios y guiones
    nit = nit.replaceAll(RegExp(r'[\s-]'), '');
    
    // Debe tener entre 9 y 10 dígitos
    if (nit.length < 9 || nit.length > 10) {
      return false;
    }
    
    // Debe contener solo números
    return RegExp(r'^\d+$').hasMatch(nit);
  }
}