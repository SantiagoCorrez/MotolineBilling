import 'package:flutter/material.dart';
import '../models/products.dart';
import '../services/product_service.dart';
import '../widgets/cart_widget.dart';
import '../widgets/dotted_background.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _productService = ProductService();
  final _searchController = TextEditingController();
  final List<CartItem> _cartItems = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _searchProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.brand.toLowerCase().contains(query.toLowerCase()) ||
              product.category.toLowerCase().contains(query.toLowerCase()) ||
              product.sku.toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(product: product));
      }
    });

  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQuantity;
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cartItems.removeAt(index));
  }

  void _updateDiscount(double discount) {
    setState(() => _discount = discount);
  }

  Future<void> _proceedToInvoice() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío')),
      );
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      '/invoice',
      arguments: {
        'cartItems': _cartItems,
        'discount': _discount,
      },
    );

    if (result == true) {
      setState(() {
        _cartItems.clear();
        _discount = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoLine - Facturación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: DottedBackground(
        child: Row(
          children: [
            Expanded(
              flex: isTablet ? 2 : 1,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Código SKU', // Changed to match image
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.transparent, // Transparent to show border clearly
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white70),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchProducts('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _searchProducts,
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.white24,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No se encontraron productos',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isTablet ? 3 : 2,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return _ProductCard(
                                    product: product,
                                    onAddToCart: () => _addToCart(product),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            if (isTablet)
              Container(
                width: 450, // Slightly wider for the list view
                decoration: BoxDecoration(
                  color: Colors.transparent, // Transparent for dotted background
                  border: const Border(left: BorderSide(color: Colors.white24)),
                ),
                child: CartWidget(
                  cartItems: _cartItems,
                  discount: _discount,
                  onUpdateQuantity: _updateQuantity,
                  onRemoveItem: _removeFromCart,
                  onUpdateDiscount: _updateDiscount,
                  onProceedToInvoice: _proceedToInvoice,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: !isTablet && _cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: const Color(0xFF1E1E2C),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.9,
                    minChildSize: 0.5,
                    expand: false,
                    builder: (context, scrollController) => CartWidget(
                      cartItems: _cartItems,
                      discount: _discount,
                      onUpdateQuantity: _updateQuantity,
                      onRemoveItem: _removeFromCart,
                      onUpdateDiscount: _updateDiscount,
                      onProceedToInvoice: () {
                        Navigator.pop(context);
                        _proceedToInvoice();
                      },
                      scrollController: scrollController,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: Text('Ver Carrito (${_cartItems.length})'),
            )
          : null,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF2D2D3F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white10,
                          child: const Icon(Icons.image_not_supported, size: 48, color: Colors.white24),
                        );
                      },
                    )
                  : Container(
                      color: Colors.white10,
                      child: const Icon(Icons.image, size: 48, color: Colors.white24),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.brand,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.greenAccent,
                      ),
                    ),
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddToCart ,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}