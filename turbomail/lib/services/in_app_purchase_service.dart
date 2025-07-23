import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseService extends ChangeNotifier {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Product IDs for different subscription plans (from Play Store)
  static const String monthlyProductId = 'monthly001';
  static const String threeMonthProductId = 'monthly003';
  static const String sixMonthProductId = 'monthly006';
  static const String yearlyProductId = 'yearly001';

  static const Set<String> _productIds = {
    monthlyProductId,
    threeMonthProductId,
    sixMonthProductId,
    yearlyProductId,
  };

  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  // Getters
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  String? get queryProductError => _queryProductError;

  Future<void> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      _isAvailable = false;
      notifyListeners();
      return;
    }

    _isAvailable = available;
    
    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    // Load products
    await loadProducts();
    
    // Restore purchases
    await restorePurchases();
    
    notifyListeners();
  }

  Future<void> loadProducts() async {
    try {
      debugPrint('Loading products with IDs: $_productIds');
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
      
      debugPrint('Products found: ${response.productDetails.length}');
      debugPrint('Products not found: ${response.notFoundIDs}');
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found in store: ${response.notFoundIDs}');
        debugPrint('Make sure these subscription IDs exist in your Play Store Console:');
        for (String id in response.notFoundIDs) {
          debugPrint('  - $id');
        }
      }
      
      if (response.error != null) {
        _queryProductError = response.error!.message;
        debugPrint('Error loading products: ${response.error!.message}');
        debugPrint('Error code: ${response.error!.code}');
      } else {
        _products = response.productDetails;
        _queryProductError = null;
        debugPrint('Successfully loaded ${_products.length} products');
        for (var product in _products) {
          debugPrint('Product: ${product.id} - ${product.title} - ${product.price}');
        }
      }
      
      notifyListeners();
    } catch (e) {
      _queryProductError = e.toString();
      debugPrint('Exception loading products: $e');
      notifyListeners();
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    if (!_isAvailable) {
      debugPrint('In-app purchases not available');
      return;
    }

    _purchasePending = true;
    notifyListeners();

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      // Use buyNonConsumable for subscriptions
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error buying product: $e');
      _purchasePending = false;
      notifyListeners();
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  void _handlePurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      
      // Verify purchase on your server here if needed
      _verifyPurchase(purchaseDetails);
      
      // Add to purchases list if not already present
      if (!_purchases.any((p) => p.productID == purchaseDetails.productID)) {
        _purchases.add(purchaseDetails);
      }
    }

    if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint('Purchase error: ${purchaseDetails.error}');
    }

    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.error) {
      _purchasePending = false;
    }

    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }

    notifyListeners();
  }

  void _verifyPurchase(PurchaseDetails purchaseDetails) {
    // Implement server-side verification here
    // For now, we'll just mark it as verified locally
    debugPrint('Purchase verified: ${purchaseDetails.productID}');
  }

  bool isPremiumActive() {
    return _purchases.any((purchase) => 
      _productIds.contains(purchase.productID) &&
      (purchase.status == PurchaseStatus.purchased || 
       purchase.status == PurchaseStatus.restored)
    );
  }

  String? getActivePremiumPlan() {
    final activePurchase = _purchases.firstWhere(
      (purchase) => _productIds.contains(purchase.productID) &&
        (purchase.status == PurchaseStatus.purchased || 
         purchase.status == PurchaseStatus.restored),
      orElse: () => throw StateError('No active premium plan'),
    );
    
    try {
      return activePurchase.productID;
    } catch (e) {
      return null;
    }
  }

  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // Helper method to get formatted price
  String getFormattedPrice(String productId) {
    final product = getProductById(productId);
    return product?.price ?? 'N/A';
  }

  // Helper method to get plan duration
  String getPlanDuration(String productId) {
    switch (productId) {
      case monthlyProductId:
        return 'Monthly';
      case threeMonthProductId:
        return '3 Months';
      case sixMonthProductId:
        return '6 Months';
      case yearlyProductId:
        return 'Yearly';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get savings percentage
  String getSavingsPercentage(String productId) {
    switch (productId) {
      case threeMonthProductId:
        return 'Save 10%';
      case sixMonthProductId:
        return 'Save 20%';
      case yearlyProductId:
        return 'Save 33%';
      default:
        return '';
    }
  }
}