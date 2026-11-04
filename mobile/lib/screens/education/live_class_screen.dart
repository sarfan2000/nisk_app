import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nisk_app/services/api_service.dart';

class LiveClassScreen extends StatefulWidget {
  final String channelName;

  const LiveClassScreen({super.key, required this.channelName});

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  RtcEngine? _engine;
  bool _muted = false;
  bool _videoDisabled = false;
  bool _isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    if (!kIsWeb) {
      await [Permission.microphone, Permission.camera].request();
    }

    final ApiService api = ApiService();
    try {
      final response = await api.get('/education/agora-token?channelName=${widget.channelName}');
      String token = response['token'];
      String appId = response['appID'];
      
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            if (mounted) setState(() => _localUserJoined = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("remote user $remoteUid joined");
            if (mounted) setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint("remote user $remoteUid left channel");
            if (mounted) setState(() => _remoteUid = null);
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('[onError] err: $err, msg: $msg');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agora Error ($err): $msg')));
            }
          },
        ),
      );

      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.enableAudio();
      await engine.enableVideo();
      await engine.startPreview();

      await engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );

      if (mounted) {
        setState(() {
          _engine = engine;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to join room: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    if (_engine != null) {
      try {
        await _engine!.leaveChannel();
        await _engine!.release();
      } catch (_) {}
    }
  }

  void _onToggleMute() {
    if (_engine == null) return;
    setState(() => _muted = !_muted);
    _engine!.muteLocalAudioStream(_muted);
  }

  void _onToggleVideo() {
    if (_engine == null) return;
    setState(() => _videoDisabled = !_videoDisabled);
    _engine!.muteLocalVideoStream(_videoDisabled);
  }

  Future<void> _onToggleScreenShare() async {
    if (_engine == null) return;
    try {
      if (_isScreenSharing) {
        await _engine!.stopScreenCapture();
        await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
          publishCameraTrack: true,
          publishScreenTrack: false,
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
        ));
        if (mounted) setState(() => _isScreenSharing = false);
      } else {
        await _engine!.startScreenCapture(const ScreenCaptureParameters2(captureAudio: true, captureVideo: true));
        await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
          publishCameraTrack: false,
          publishScreenTrack: kIsWeb ? true : false,
          publishScreenCaptureVideo: kIsWeb ? false : true,
          publishScreenCaptureAudio: kIsWeb ? false : true,
        ));
        if (mounted) setState(() => _isScreenSharing = true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Screen share error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Class: ${widget.channelName}'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 120,
              height: 160,
              child: Center(
                child: _localUserJoined && _engine != null
                  ? (_videoDisabled && !_isScreenSharing
                      ? Container(color: Colors.black, child: const Center(child: Icon(Icons.videocam_off, color: Colors.white)))
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine!, 
                            canvas: VideoCanvas(
                              uid: 0, 
                              sourceType: _isScreenSharing ? VideoSourceType.videoSourceScreen : VideoSourceType.videoSourceCamera,
                              renderMode: RenderModeType.renderModeHidden,
                            ),
                            useFlutterTexture: kIsWeb ? false : true,
                          ),
                        ))
                  : const CircularProgressIndicator(),
              ),
            ),
          ),
          _toolbar(),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null && _engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(
            uid: _remoteUid,
            renderMode: RenderModeType.renderModeHidden,
          ),
          connection: RtcConnection(channelId: widget.channelName),
          useFlutterTexture: kIsWeb ? false : true,
        ),
      );
    } else {
      return const Text('Waiting for other user to join', textAlign: TextAlign.center);
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: _onToggleMute,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(15.0),
            child: Icon(
              _muted ? Icons.mic_off : Icons.mic,
              color: _muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(Icons.call_end, color: Colors.white, size: 35.0),
          ),
          RawMaterialButton(
            onPressed: _onToggleVideo,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _videoDisabled ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(15.0),
            child: Icon(
              _videoDisabled ? Icons.videocam_off : Icons.videocam,
              color: _videoDisabled ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: _onToggleScreenShare,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _isScreenSharing ? Colors.green : Colors.white,
            padding: const EdgeInsets.all(15.0),
            child: Icon(
              _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              color: _isScreenSharing ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          )
        ],
      ),
    );
  }
}
