import 'package:ecommerce_app/models/product.dart';

/// Deterministic product fixtures shared by the test suite.
///
/// Tests must never hit the live FakeStore API: it is a third-party service and
/// a red suite caused by someone else's downtime teaches us nothing.
final List<Product> fakeProducts = [
  Product(
    id: 1,
    title: 'Fjallraven Foldsack No. 1 Backpack',
    price: 109.95,
    description: 'Your perfect pack for everyday use and walks in the forest.',
    image: 'https://example.test/backpack.png',
    category: "men's clothing",
    rating: 3.9,
    ratingCount: 120,
  ),
  Product(
    id: 2,
    title: 'Mens Casual Premium Slim Fit T-Shirts',
    price: 22.3,
    description: 'Slim-fit style, contrast raglan long sleeve.',
    image: 'https://example.test/tshirt.png',
    category: "men's clothing",
    rating: 4.1,
    ratingCount: 259,
  ),
  Product(
    id: 3,
    title: 'John Hardy Gold Bracelet',
    price: 695.0,
    description: 'Chain bracelet inspired by the mythical water dragon.',
    image: 'https://example.test/bracelet.png',
    category: 'jewelery',
    rating: 4.6,
    ratingCount: 400,
  ),
];

/// A raw API payload matching the shape FakeStore returns, for parser tests.
const Map<String, dynamic> fakeProductJson = {
  'id': 1,
  'title': 'Fjallraven Foldsack No. 1 Backpack',
  'price': 109.95,
  'description': 'Your perfect pack for everyday use and walks in the forest.',
  'category': "men's clothing",
  'image': 'https://example.test/backpack.png',
  'rating': {'rate': 3.9, 'count': 120},
};

/// Builds [count] distinct products, for paging and grid tests.
///
/// Prices and ratings vary so sort assertions in later tasks have something to
/// bite on.
List<Product> fakeCatalog(int count) => List.generate(
      count,
      (index) => Product(
        id: index + 1,
        title: 'Product ${index + 1}',
        price: (index + 1) * 5.5,
        description: 'Description for product ${index + 1}',
        image: 'https://example.test/product-${index + 1}.png',
        category: index.isEven ? 'electronics' : 'jewelery',
        rating: 1 + (index % 5).toDouble(),
        ratingCount: 10 + index,
      ),
    );
