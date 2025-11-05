/// Razorpay Payment Gateway Configuration
/// 
/// NOTE: For production, replace these values with your actual Razorpay API keys
/// You can get these from: https://dashboard.razorpay.com/app/keys
/// 
/// To use environment variables in production:
/// ```dart
/// static const String keyId = String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'your_test_key');
/// ```
class RazorpayConfig {
  // Razorpay Key ID from https://dashboard.razorpay.com/app/keys
  // Test keys for development (replace with live keys for production)
  static const String keyId = 'rzp_test_RDouHU48fIRw7R';
  
  // Live Darshan payment amount (in paise - 1 rupee = 100 paise)
  static const int liveDarshanAmount = 100; // ₹1.00
  
  // Payment description
  static const String liveDarshanDescription = 'Live Darshan Access';
  static const String liveDarshanName = 'R-Gram';
  
  // For production, use environment variables:
  // static const String keyId = String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_xxxxx');
}
