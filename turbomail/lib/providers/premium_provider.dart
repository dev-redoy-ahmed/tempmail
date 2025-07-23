import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/in_app_purchase_service.dart';

class PremiumProvider extends ChangeNotifier {
  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  bool _isPremium = false;
  String? _activePlan;
  bool _isLoading = false;

  bool get isPremium => _isPremium;
  String? get activePlan => _activePlan;
  bool get isLoading => _isLoading;
  InAppPurchaseService get purchaseService => _purchaseService;

  PremiumProvider() {
    _initializePremium();
  }

  Future<void> _initializePremium() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Initializing premium provider...');
      
      // Load saved premium status first
      await _loadPremiumStatus();
      
      // Initialize in-app purchase service
      debugPrint('Initializing in-app purchase service...');
      await _purchaseService.initialize();
      
      // Check premium status
      debugPrint('Checking premium status...');
      await checkPremiumStatus();
      
      // Listen to purchase service changes
      _purchaseService.addListener(_onPurchaseServiceUpdate);
      
      debugPrint('Premium provider initialization complete');
    } catch (e) {
      debugPrint('Error initializing premium: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onPurchaseServiceUpdate() {
    checkPremiumStatus();
  }

  Future<void> checkPremiumStatus() async {
    try {
      final bool premiumActive = _purchaseService.isPremiumActive();
      final String? plan = _purchaseService.getActivePremiumPlan();
      
      if (_isPremium != premiumActive || _activePlan != plan) {
        _isPremium = premiumActive;
        _activePlan = plan;
        
        // Save to local storage
        await _savePremiumStatus();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking premium status: $e');
    }
  }

  Future<void> _savePremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', _isPremium);
      if (_activePlan != null) {
        await prefs.setString('active_plan', _activePlan!);
      } else {
        await prefs.remove('active_plan');
      }
    } catch (e) {
      debugPrint('Error saving premium status: $e');
    }
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('is_premium') ?? false;
      _activePlan = prefs.getString('active_plan');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading premium status: $e');
    }
  }

  Future<void> purchasePlan(String productId) async {
    try {
      debugPrint('Attempting to purchase plan: $productId');
      final product = _purchaseService.getProductById(productId);
      if (product != null) {
        debugPrint('Product found: ${product.title} - ${product.price}');
        await _purchaseService.buyProduct(product);
      } else {
        debugPrint('Product not found for ID: $productId');
        debugPrint('Available products: ${_purchaseService.products.map((p) => p.id).toList()}');
        throw Exception('Product not found: $productId');
      }
    } catch (e) {
      debugPrint('Error purchasing plan: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _purchaseService.restorePurchases();
      await checkPremiumStatus();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getPlanDisplayName(String? productId) {
    if (productId == null) return 'Free';
    return _purchaseService.getPlanDuration(productId);
  }

  String getPlanPrice(String productId) {
    return _purchaseService.getFormattedPrice(productId);
  }

  String getPlanSavings(String productId) {
    return _purchaseService.getSavingsPercentage(productId);
  }

  // Premium features check methods
  bool canCreateUnlimitedEmails() => _isPremium;
  bool canUseExtendedDuration() => _isPremium;
  bool hasEnhancedSecurity() => _isPremium;
  bool hasPrioritySupport() => _isPremium;
  bool hasAdFreeExperience() => _isPremium;

  @override
  void dispose() {
    _purchaseService.removeListener(_onPurchaseServiceUpdate);
    super.dispose();
  }
}