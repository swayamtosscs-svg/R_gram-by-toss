import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/razorpay_config.dart';

/// Razorpay Payment Service for Live Darshan Access
/// 
/// Handles payment processing for Live Darshan feature
/// Platform: Android only (as per requirements)
class RazorpayPaymentService {
  static final RazorpayPaymentService _instance = RazorpayPaymentService._internal();
  factory RazorpayPaymentService() => _instance;
  RazorpayPaymentService._internal();

  Razorpay? _razorpay;
  Function(String paymentId)? _onPaymentSuccess;
  Function(String error)? _onPaymentError;

  /// Initialize Razorpay instance
  void initialize() {
    if (!kIsWeb && Platform.isAndroid) {
      _razorpay = Razorpay();
      _setupEventListeners();
    }
  }

  /// Setup event listeners for payment callbacks
  void _setupEventListeners() {
    if (_razorpay == null) return;

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    debugPrint('Payment Success - Order ID: ${response.orderId}');
    debugPrint('Payment Success - Signature: ${response.signature}');
    
    // Call success callback on next frame to ensure proper context
    if (_onPaymentSuccess != null) {
      Future.microtask(() {
        _onPaymentSuccess!(response.paymentId ?? '');
      });
    } else {
      debugPrint('ERROR: Payment success callback is null!');
    }
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    String errorMessage = 'Payment failed';
    
    switch (response.code) {
      case Razorpay.NETWORK_ERROR:
        errorMessage = 'Network error. Please check your internet connection.';
        break;
      case Razorpay.INVALID_OPTIONS:
        errorMessage = 'Invalid payment options. Please try again.';
        break;
      case Razorpay.PAYMENT_CANCELLED:
        errorMessage = 'Payment was cancelled.';
        break;
      case Razorpay.TLS_ERROR:
        errorMessage = 'Device does not support secure payment.';
        break;
      default:
        errorMessage = response.message ?? 'Payment failed. Please try again.';
    }
    
    debugPrint('Payment Error: ${response.code} - $errorMessage');
    if (_onPaymentError != null) {
      _onPaymentError!(errorMessage);
    }
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet Selected: ${response.walletName}');
    // External wallet is handled by Razorpay, no action needed
  }

  /// Check if Razorpay is supported on current platform
  bool isSupported() {
    return !kIsWeb && Platform.isAndroid;
  }

  /// Process Live Darshan payment (₹1)
  /// 
  /// [onSuccess] - Callback when payment succeeds (receives payment ID)
  /// [onError] - Callback when payment fails (receives error message)
  Future<void> processLiveDarshanPayment({
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
    String? userEmail,
    String? userContact,
  }) async {
    if (!isSupported()) {
      onError('Payment is only supported on Android devices.');
      return;
    }

    if (_razorpay == null) {
      initialize();
    }

    if (_razorpay == null) {
      onError('Payment service is not available. Please try again.');
      return;
    }

    // Set callbacks
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;

    // Prepare payment options
    final options = {
      'key': RazorpayConfig.keyId,
      'amount': RazorpayConfig.liveDarshanAmount, // ₹1.00 in paise
      'name': RazorpayConfig.liveDarshanName,
      'description': RazorpayConfig.liveDarshanDescription,
      'prefill': {
        if (userContact != null) 'contact': userContact,
        if (userEmail != null) 'email': userEmail,
      },
      'theme': {
        'color': '#673AB7', // Deep purple theme
      },
    };

    try {
      // Open Razorpay checkout
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      onError('Failed to open payment gateway. Please try again.');
    }
  }

  /// Clear all event listeners
  void dispose() {
    _razorpay?.clear();
    _onPaymentSuccess = null;
    _onPaymentError = null;
  }
}
