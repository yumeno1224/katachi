import 'package:flutter/material.dart';
// ignore: unused_import
import 'main.dart';
import 'timeattack.dart';
import 'shapematch.dart';
import 'package:audioplayers/audioplayers.dart'; // ✅ こっちだけでOK

class ModeSelectionScreen extends StatefulWidget {
  @override
  _ModeSelectionScreenState createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> shapes = ['circle', 'triangle', 'square', 'star', 'heart'];

  Future<void> _playSoundAndNavigate(Widget page) async {
    await _audioPlayer.play(AssetSource('sounds/grab.wav')); // ✅ AudioCacheなしで再生
    await Future.delayed(Duration(milliseconds: 100));
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景図形
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: shapes.asMap().entries.map((entry) {
                final i = entry.key;
                final shape = entry.value;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: FloatingShape(
                    shape: shape,
                    delay: i * 300,
                  ),
                );
              }).toList(),
            ),
          ),

          // ボタン群
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _playSoundAndNavigate(ShapeMatchGame()),
                  child: Text('かんたんモード'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _playSoundAndNavigate(TimeAttackHome()),
                  child: Text('タイムアタック'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class FloatingShape extends StatefulWidget {
  final String shape;
  final int delay;

  FloatingShape({required this.shape, this.delay = 0});

  @override
  _FloatingShapeState createState() => _FloatingShapeState();
}

class _FloatingShapeState extends State<FloatingShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetY;
  bool isMovingUp = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _offsetY = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && isMovingUp) {
        isMovingUp = false;
        _controller.stop();
        await Future.delayed(Duration(milliseconds: 1600));
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed && !isMovingUp) {
        isMovingUp = true;
        _controller.stop();
        await Future.delayed(Duration(milliseconds: 1600));
        _controller.forward();
      }
    });

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _offsetY.value),
        child: Opacity(
          opacity: 0.5,
          child: Image.asset(
            'assets/images/${widget.shape}.png',
            width: 50,
            height: 50,
          ),
        ),
      ),
    );
  }
}
