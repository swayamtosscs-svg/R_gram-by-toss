import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import '../config/zego_config.dart';

/// ZegoCloud Live Streaming Screen
/// 
/// This screen allows users to start or join a live stream using ZegoCloud SDK.
/// 
/// Parameters:
/// - [userID]: Unique identifier for the user (required)
/// - [userName]: Display name of the user (required)
/// - [liveID]: Unique identifier for the live stream session (required)
/// - [isHost]: Whether this user is the host (true) or viewer (false)
class ZegoLiveStreamingScreen extends StatelessWidget {
  final String userID;
  final String userName;
  final String liveID;
  final bool isHost;

  const ZegoLiveStreamingScreen({
    Key? key,
    required this.userID,
    required this.userName,
    required this.liveID,
    required this.isHost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ZegoCloud Live Streaming UI
            ZegoUIKitPrebuiltLiveStreaming(
              appID: ZegoConfig.appID,
              appSign: ZegoConfig.appSign,
              userID: userID,
              userName: userName,
              liveID: liveID,
              config: isHost
                  ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
                  : ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
            ),
            
            // Stream ID Display (Only for Host) - positioned to avoid overlapping back button
            if (isHost)
              Positioned(
                top: 16,
                left: 60, // Leave space for back button on the left (ZegoCloud UI back button area)
                child: _buildStreamIDCard(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamIDCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stream ID Icon
            Icon(
              Icons.video_call,
              color: Colors.red,
              size: 18,
            ),
            const SizedBox(width: 8),
            
            // Stream ID Text
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Stream ID',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    liveID,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 6),
            
            // Copy Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: liveID));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Stream ID Copied!',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.copy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

