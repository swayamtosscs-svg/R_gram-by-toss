/// ZegoCloud Live Streaming Configuration
/// 
/// NOTE: For production, replace these values with your actual ZegoCloud credentials
/// You can get these from: https://console.zegocloud.com/
/// 
/// To use environment variables in production:
/// ```dart
/// static const int appID = int.parse(String.fromEnvironment('ZEGO_APP_ID', defaultValue: '1348072164'));
/// static const String appSign = String.fromEnvironment('ZEGO_APP_SIGN', defaultValue: 'your_default_app_sign');
/// ```
class ZegoConfig {
  // TODO: Replace with your actual ZegoCloud App ID and App Sign from https://console.zegocloud.com/
  static const int appID = 1348072164;
  static const String appSign = "c4c9a9c236b4c11d7d644cb4934a91a518f507a9b3cdeb41c910bb1538d7e785";

  // For production, use environment variables:
  // static const int appID = int.parse(String.fromEnvironment('ZEGO_APP_ID', defaultValue: '1348072164'));
  // static const String appSign = String.fromEnvironment('ZEGO_APP_SIGN', defaultValue: '');
}


