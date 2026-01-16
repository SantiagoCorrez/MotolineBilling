class Product {
  final String id;
  final int sku;
  final String name;
  final double price;
  final String desc;
  final int stock;
  final List<String> images;
  final String brand;
  final String category;
  final String marcaVehicular;
  final String referenciaVehiculo;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.desc,
    required this.stock,
    required this.images,
    required this.brand,
    required this.category,
    this.marcaVehicular = '',
    this.referenciaVehiculo = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['_id'] ?? '',
      sku: json['sku'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      desc: json['desc'] ?? '',
      stock: json['stock'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      marcaVehicular: json['Marcavehicular'] ?? '',
      referenciaVehiculo: json['ReferenciaVehiculo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id':  id,
      'sku': sku,
      'name': name,
      'price': price,
      'desc': desc,
      'stock': stock,
      'images': images,
      'brand': brand,
      'category': category,
      'Marcavehicular': marcaVehicular,
      'ReferenciaVehiculo': referenciaVehiculo,
    };
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;
}