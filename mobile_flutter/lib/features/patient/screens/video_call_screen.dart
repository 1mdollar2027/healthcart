import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String consultationId;
  const VideoCallScreen({super.key, required this.consultationId});
  @override State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _loading = true;
  bool _muted = false;
  bool _videoOff = false;
  String _channelName = '';
  int _seconds = 0;
  bool _connected = false;

  @override void initState() { super.initState(); _joinCall(); }

  Future<void> _joinCall() async {
    try {
      final data = await ApiService.getConsultationToken(widget.consultationId);
      _channelName = data['channel_name'] ?? '';
      // In production, use Agora RtcEngine to join the channel
      // For now, simulate a connected state
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() { _loading = false; _connected = true; });
      _startTimer();
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_connected) return false;
      setState(() => _seconds++);
      return true;
    });
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _endCall() async {
    try {
      await ApiService.endConsultation(widget.consultationId, {});
    } catch (_) {}
    if (mounted) { setState(() => _connected = false); context.go('/patient'); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: _loading ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text('Connecting...', style: TextStyle(color: Colors.white70, fontSize: 16)),
        Text('Setting up secure video call', style: TextStyle(color: Colors.white38, fontSize: 13)),
      ])) : Stack(
        children: [
          // Doctor video (full screen placeholder)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [HealthCartTheme.primary.withOpacity(0.3), const Color(0xFF1A1A2E)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(radius: 50, backgroundColor: Colors.white12,
                child: Icon(Icons.person_rounded, size: 50, color: Colors.white38)),
              SizedBox(height: 16),
              Text('Doctor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              Text('Connected', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ])),
          ),
          // Self view (small, bottom-right)
          Positioned(right: 16, bottom: 120, child: Container(
            width: 100, height: 140,
            decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Center(child: Icon(Icons.person_rounded, size: 36, color: Colors.white38)),
          )),
          // Top bar (timer + channel)
          Positioned(top: 60, left: 0, right: 0, child: Column(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: HealthCartTheme.success, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(_formattedTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ]),
            ),
            const SizedBox(height: 4),
            Text('🔒 Encrypted Call', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          // Bottom controls
          Positioned(left: 0, right: 0, bottom: 40, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _controlBtn(Icons.mic_off_rounded, Icons.mic_rounded, _muted, () => setState(() => _muted = !_muted), Colors.white),
            _controlBtn(Icons.videocam_off_rounded, Icons.videocam_rounded, _videoOff, () => setState(() => _videoOff = !_videoOff), Colors.white),
            GestureDetector(
              onTap: _endCall,
              child: Container(padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(color: HealthCartTheme.error, shape: BoxShape.circle),
                child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28)),
            ),
            _controlBtn(Icons.flip_camera_ios_rounded, Icons.flip_camera_ios_rounded, false, () {}, Colors.white),
            _controlBtn(Icons.chat_rounded, Icons.chat_rounded, false, () {}, Colors.white),
          ])),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData off, IconData on_, bool isOff, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isOff ? Colors.white24 : Colors.white12, shape: BoxShape.circle),
        child: Icon(isOff ? off : on_, color: color, size: 24)),
    );
  }
}
