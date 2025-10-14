import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/settings.dart';

class CallPage extends StatefulWidget {
  final String channelName;
  final RoleOptions role;

  const CallPage({super.key, required this.channelName, required this.role});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isFrontCamera = true;
  bool _muted = false;

  late Timer _timer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    initAgora();
    startTimer();
  }

  Future<void> initAgora() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    await _engine.enableVideo();

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          log("Local user joined: ${connection.localUid}");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          log("Remote user joined: $remoteUid");
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          log("Remote user left: $remoteUid");
          setState(() => _remoteUid = null);
        },
      ),
    );

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType:
            widget.role == RoleOptions.Broadcaster
                ? ClientRoleType.clientRoleBroadcaster
                : ClientRoleType.clientRoleAudience,
      ),
    );
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _switchCamera() {
    _engine.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  void _toggleMute() {
    _muted = !_muted;
    _engine.muteLocalAudioStream(_muted);
    setState(() {});
  }

  void _endCall() {
    _timer.cancel();
    _engine.leaveChannel();
    _engine.release();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Channel: ${widget.channelName}")),
      body: Stack(
        children: [
          // Remote video
          _remoteUid != null
              ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              )
              : const Center(child: Text("Waiting for user to join")),

          // Local video
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 120,
              height: 160,
              child:
                  _localUserJoined
                      ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                      : const Center(child: CircularProgressIndicator()),
            ),
          ),

          // Bottom control bar
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.black.withValues(alpha: .4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Call duration
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  // Switch camera
                  IconButton(
                    onPressed: _switchCamera,
                    icon: Icon(
                      _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                      color: Colors.white,
                    ),
                  ),

                  // Mute / unmute
                  IconButton(
                    onPressed: _toggleMute,
                    icon: Icon(
                      _muted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                  ),

                  // End call
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(Icons.call_end, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
