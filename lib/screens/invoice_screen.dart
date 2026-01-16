import 'package:flutter/material.dart';
import '../models/products.dart';
import '../services/invoice_service.dart';
import '../services/printer_service.dart';
import '../widgets/dotted_background.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _cedulaController = TextEditingController();
  
  final _invoiceService = InvoiceService();
  final _printerService = PrinterService();
  
  bool _isProcessing = false;
  bool _electronicInvoice = true;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  Future<void> _generateInvoice(
    List<CartItem> cartItems,
    double discount,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final invoiceData = {
        'customerName': _nameController.text,
        'customerId': _idController.text,
        'customerEmail': _emailController.text,
        'customerCedula': _cedulaController.text,
        'items': cartItems.map((item) => {
          'productId': item.product.id,
          'productName': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
        }).toList(),
        'discount': discount,
        'total': cartItems.fold<double>(0, (sum, item) => sum + item.subtotal),
        'totalWithDiscount': cartItems.fold<double>(0, (sum, item) => sum + item.subtotal) * (1 - discount / 100),
        'isElectronic': _electronicInvoice,
        'timestamp': DateTime.now().toIso8601String(),
      };

      String invoiceNumber;

      print(invoiceData);
      if (_electronicInvoice) {
        // Generar factura electrónica DIAN
        invoiceNumber = await _invoiceService.generateElectronicInvoice(invoiceData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factura electrónica generada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Generar factura normal
        invoiceNumber = await _invoiceService.generateNormalInvoice(invoiceData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factura generada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Mostrar diálogo de impresión
      if (mounted) {
        final shouldPrint = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D3F),
            title: const Text('Factura Generada', style: TextStyle(color: Colors.white)),
            content: Text(
              'Factura #$invoiceNumber generada exitosamente.\n\n¿Desea imprimir la factura?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Imprimir'),
              ),
            ],
          ),
        );

        if (shouldPrint == true) {
          await _printInvoice(invoiceData, invoiceNumber);
        }

        // Regresar a la pantalla de productos
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar factura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _printInvoice(Map<String, dynamic> invoiceData, String invoiceNumber) async {
    try {
      await _printerService.printInvoice(invoiceData, invoiceNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impresión enviada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final cartItems = args['cartItems'] as List<CartItem>;
    final discount = args['discount'] as double;

    final total = cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);
    final totalWithDiscount = total * (1 - discount / 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos del Cliente'),
      ),
      body: DottedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      color: const Color(0xFF2D2D3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ingrese datos del cliente',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person, color: Colors.white70),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _idController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Cédula/Nit',
                                prefixIcon: Icon(Icons.badge, color: Colors.white70),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo',
                                prefixIcon: Icon(Icons.email, color: Colors.white70),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo requerido';
                                }
                                if (!value.contains('@')) {
                                  return 'Correo inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cedulaController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Cédula',
                                prefixIcon: Icon(Icons.credit_card, color: Colors.white70),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo requerido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      color: const Color(0xFF2D2D3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo de Factura',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Generar Factura Electrónica DIAN', style: TextStyle(color: Colors.white)),
                              subtitle: const Text('Desactivar para factura normal', style: TextStyle(color: Colors.white70)),
                              value: _electronicInvoice,
                              onChanged: (value) {
                                setState(() => _electronicInvoice = value);
                              },
                              secondary: Icon(
                                _electronicInvoice 
                                    ? Icons.description 
                                    : Icons.receipt,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.blue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: 'Subtotal:',
                              value: '\$${total.toStringAsFixed(0)}',
                              color: Colors.white,
                            ),
                            if (discount > 0) ...[
                              const SizedBox(height: 8),
                              _SummaryRow(
                                label: 'Descuento ($discount%):',
                                value: '-\$${(total * discount / 100).toStringAsFixed(0)}',
                                color: Colors.redAccent,
                              ),
                            ],
                            const Divider(height: 24, color: Colors.white24),
                            _SummaryRow(
                              label: 'TOTAL:',
                              value: '\$${totalWithDiscount.toStringAsFixed(0)}',
                              bold: true,
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isProcessing ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _generateInvoice(cartItems, discount),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Aceptar',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final double fontSize;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.fontSize = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.white70,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.greenAccent,
          ),
        ),
      ],
    );
  }
}