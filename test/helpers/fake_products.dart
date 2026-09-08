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
    rating: 3.9,
  ),
  Product(
    id: 2,
    title: 'Mens Casual Premium Slim Fit T-Shirts',
    price: 22.3,
    description: 'Slim-fit style, contrast raglan long sleeve.',
    image: 'https://example.test/tshirt.png',
    rating: 4.1,
  ),
  Product(
    id: 3,
    title: 'John Hardy Gold Bracelet',
    price: 695.0,
    description: 'Chain bracelet inspired by the mythical water dragon.',
    image: 'https://example.test/bracelet.png',
    rating: 4.6,
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
