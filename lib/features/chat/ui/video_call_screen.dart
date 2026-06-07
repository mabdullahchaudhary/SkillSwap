import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class VideoCallScreen extends StatelessWidget {
  final String roomId;
  final String partnerName;
  final bool isVideoCall;

  const VideoCallScreen({
    super.key,
    required this.roomId,
    required this.partnerName,
    required this.isVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    const int appId = 2104295772;
    const String appSign =
        "dcb2c499201c70d3587c6edb7fc9afbe3b3c55ce48a818b3fb7104053aa8e2f3";

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: appId,
        appSign: appSign,
        userID: user.uid,
        userName: user.displayName ?? "Skill Swapper",
        callID: roomId,

        config: isVideoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
      ),
    );
  }
}
