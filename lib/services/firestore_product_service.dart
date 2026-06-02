import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartshopper_mobile/data/models/index.dart';

/// Product service that fetches real-time data from Firestore
class FirestoreProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============== READ ==============

  /// Get all products as a stream
  Stream<List<Product>> getProductsStream() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get all retailers as a stream
  Stream<List<Retailer>> getRetailersStream() {
    return _db.collection('retailers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Retailer.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get all prices as a stream
  Stream<List<Price>> getPricesStream() {
    return _db.collection('prices').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Price.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get products once
  Future<List<Product>> getAllProducts() async {
    final snapshot = await _db.collection('products').get();
    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get product by ID
  Future<Product?> getProductById(int id) async {
    final doc = await _db.collection('products').doc(id.toString()).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc.data()!, doc.id);
  }

  /// Get prices for a specific product
  Future<List<Price>> getPricesForProduct(int productId) async {
    final snapshot = await _db
        .collection('prices')
        .where('productId', isEqualTo: productId.toString())
        .get();
    
    // If empty, try with int (for compatibility)
    if (snapshot.docs.isEmpty) {
      final snapshotInt = await _db
          .collection('prices')
          .where('productId', isEqualTo: productId)
          .get();
      return snapshotInt.docs
          .map((doc) => Price.fromFirestore(doc.data(), doc.id))
          .toList();
    }

    return snapshot.docs
        .map((doc) => Price.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get a single retailer by ID
  Future<Retailer?> getRetailerById(int id) async {
    final doc = await _db.collection('retailers').doc(id.toString()).get();
    if (!doc.exists) return null;
    return Retailer.fromFirestore(doc.data()!, doc.id);
  }
  /// Update retailer location coordinates
  Future<void> updateRetailerLocation(int id, double lat, double lng) async {
    await _db.collection('retailers').doc(id.toString()).update({
      'latitude': lat,
      'longitude': lng,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
