import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/products.dart';
import 'auth_service.dart';

class ProductService {
  static const String baseUrl = 'https://motolineparts.com/api';
  final AuthService _authService = AuthService();

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products')
      );

      // ... código anterior ...
      if (response.statusCode == 200) {
        // Decodifica el cuerpo de la respuesta en un mapa
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Accede a la lista de productos a través de la clave 'products'
        final List<dynamic> productList = data['products'];
        // Mapea la lista a objetos Product
        return productList.map((json) => Product.fromJson(json)).toList();
      }
      throw Exception('Error al cargar productos');
    } catch (e) {
      print('Error en getProducts: $e');
      // Retorna datos de ejemplo para desarrollo
      return _getMockProducts();
    }
  }

  Future<Product?> searchProductBySku(String sku) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$sku'),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error en searchProductBySku: $e');
      return null;
    }
  }

  // Datos de ejemplo para desarrollo
  List<Product> _getMockProducts() {
    return [
      Product(
        id: '1',
        sku: 860789879,
        name: 'Mobil 20w-50',
        price: 29000,
        desc: 'El aceite de motor 20w50 protege el motor de la corrosión',
        stock: 70,
        images: ['https://via.placeholder.com/300x300?text=Mobil+20w-50'],
        brand: 'MOBIL',
        category: 'Aceites y lubricantes',
      ),
      Product(
        id: '2',
        sku: 79089789879,
        name: 'Motul 5100 10W-40',
        price: 40000,
        desc: 'Aceite semi-sintético de alta calidad',
        stock: 50,
        images: ['https://via.placeholder.com/300x300?text=Motul+5100'],
        brand: 'MOTUL',
        category: 'Aceites y lubricantes',
      ),
      Product(
        id: '3',
        sku: 909789879,
        name: 'Filtro de Aceite',
        price: 15000,
        desc: 'Filtro de aceite universal',
        stock: 100,
        images: ['https://via.placeholder.com/300x300?text=Filtro'],
        brand: 'GENERIC',
        category: 'Filtros',
      ),
      Product(
        id: '4',
        sku: 789789876,
        name: 'Bujía NGK',
        price: 12000,
        desc: 'Bujía de alta calidad',
        stock: 80,
        images: ['https://via.placeholder.com/300x300?text=Bujia+NGK'],
        brand: 'NGK',
        category: 'Sistema eléctrico',
      ),
      Product(
        id: '5',
        sku: 789789879,
        name: 'Cadena 520',
        price: 85000,
        desc: 'Cadena de transmisión reforzada',
        stock: 25,
        images: ['https://via.placeholder.com/300x300?text=Cadena'],
        brand: 'DID',
        category: 'Transmisión',
      ),
    ];
  }
}