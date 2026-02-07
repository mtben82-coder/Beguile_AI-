import 'dart:async';
import 'dart:io' show Platform;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'paywall_service.dart';

class BillingService {
  BillingService._();

  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  static bool _initialized = false;

  static const String _lastProductKey = 'iap_last_product_id_v1';

  // ✅ Your real product IDs
  static const String androidMonthlyId = String.fromEnvironment(
    'ANDROID_SUB_MONTHLY_ID',
    defaultValue: '1beguile_pro_monthly',
  );
  static const String androidYearlyId = String.fromEnvironment(
    'ANDROID_SUB_YEARLY_ID',
    defaultValue: '1beguile_pro_yearly',
  );

  static Completer<bool>? _pendingPurchaseCompleter;

  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      final bool available = await _inAppPurchase.isAvailable();
      print('Billing available: $available');

      _purchaseSub = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _purchaseSub?.cancel(),
        onError: (err) => print('Purchase stream error: $err'),
      );
    } catch (e) {
      print('Billing service initialization failed (likely web): $e');
      // Continue without billing on web
    }

    _initialized = true;
  }

  static Future<Map<String, ProductDetails>> loadProductsByPlan() async {
    final productIds = {
      androidMonthlyId,
      androidYearlyId,
    }.where((id) => id.trim().isNotEmpty).toSet();

    if (productIds.isEmpty) return {};

    print('🔍 Querying products: $productIds');
    final response = await _inAppPurchase.queryProductDetails(productIds);
    
    if (response.error != null) {
      print('❌ Billing load error: ${response.error}');
      return {};
    }
    
    if (response.productDetails.isEmpty) {
      print('⚠️ No products found for IDs: $productIds');
      return {};
    }

    print('✅ Found ${response.productDetails.length} products');
    for (final p in response.productDetails) {
      print('  Product: ${p.id} - ${p.title} - ${p.price}');
    }

    final byId = {for (final p in response.productDetails) p.id: p};
    final Map<String, ProductDetails> plans = {};
    
    if (byId.containsKey(androidMonthlyId)) {
      plans['monthly'] = byId[androidMonthlyId]!;
      print('✅ Monthly product loaded: $androidMonthlyId');
    } else {
      print('❌ Monthly product NOT found: $androidMonthlyId');
    }
    
    if (byId.containsKey(androidYearlyId)) {
      plans['yearly'] = byId[androidYearlyId]!;
      print('✅ Yearly product loaded: $androidYearlyId');
    } else {
      print('❌ Yearly product NOT found: $androidYearlyId');
    }
    
    return plans;
  }

  static Future<bool> buyPlan(String plan) async {
    final products = await loadProductsByPlan();
    final product = products[plan];
    if (product == null) {
      print('❌ No product found for plan: $plan');
      return false;
    }

    _pendingPurchaseCompleter = Completer<bool>();

    if (Platform.isAndroid && product is GooglePlayProductDetails) {
      print('🔍 Processing Android purchase for: $plan (${product.id})');
      final offers = product.productDetails.subscriptionOfferDetails;

      // Simple: just use the first available offer for this product.
      // The product ID already determines monthly vs yearly.
      String? offerToken;
      if (offers != null && offers.isNotEmpty) {
        offerToken = offers.first.offerIdToken;
        print('✅ Using offer for $plan: basePlanId=${offers.first.basePlanId}');
      }

      // Fallback to product-level token
      offerToken ??= product.offerToken;

      if (offerToken == null || offerToken.isEmpty) {
        print('❌ No valid offer token for $plan');
        _pendingPurchaseCompleter = null;
        return false;
      }

      final purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: offerToken,
      );

      final submitted =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!submitted) {
        _pendingPurchaseCompleter = null;
        return false;
      }
    } else {
      // iOS or other platforms
      final purchaseParam = PurchaseParam(productDetails: product);
      final submitted =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!submitted) {
        _pendingPurchaseCompleter = null;
        return false;
      }
    }

    try {
      final result = await _pendingPurchaseCompleter!.future
          .timeout(const Duration(minutes: 5));
      if (result) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastProductKey, product.id);
      }
      return result;
    } catch (_) {
      return false;
    } finally {
      _pendingPurchaseCompleter = null;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      final completer = Completer<bool>();
      final sub = _inAppPurchase.purchaseStream.listen((purchases) async {
        bool anyActive = false;
        for (final p in purchases) {
          if (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) {
            anyActive = true;
            if (p.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(p);
            }
          }
        }
        await PaywallService.setEntitled(anyActive);
        if (!completer.isCompleted) completer.complete(anyActive);
      });
      final result = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      await sub.cancel();
      return result;
    } catch (e) {
      print('❌ Restore failed: $e');
      return false;
    }
  }

  static Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
  }

  static Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    bool entitled = false;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          entitled = true;
          break;
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _inAppPurchase.completePurchase(purchase);
        } catch (e) {
          print('⚠️ Complete purchase error: $e');
        }
      }
    }

    if (entitled) {
      await PaywallService.setEntitled(true);
      _pendingPurchaseCompleter?.complete(true);
    } else {
      _pendingPurchaseCompleter?.complete(false);
    }
  }
}
