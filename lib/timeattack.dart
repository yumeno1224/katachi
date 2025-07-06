// time_attack_home.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'main.dart';

class TimeAttackHome extends StatefulWidget {
  @override
  _TimeAttackHomeState createState() => _TimeAttackHomeState();
}

class _TimeAttackHomeState extends State<TimeAttackHome> {
  final AudioPlayer grabPlayer = AudioPlayer();
  final AudioPlayer successPlayer = AudioPlayer();
  final AudioPlayer clearPlayer = AudioPlayer();

  final List<String> allShapes = ['circle', 'triangle', 'square', 'star', 'heart'];

  late List<String> draggableShapes;
  late List<String> targetShapes;
  List<String?> placedShapes = List.filled(3, null);

  int currentSet = 1;
  final int totalSets = 10;
  int correctCount = 0;

  bool isGameOver = false;
  bool isFading = false; // フェードイン用フラグ
  List<double> confettiOffsets = [];

  late DateTime endTime;
  late Timer _timer;
  int remainingSeconds = 25;
  double remainingTimeRatio = 1.0;

  @override
  void initState() {
    super.initState();
    grabPlayer.setReleaseMode(ReleaseMode.stop);
    successPlayer.setReleaseMode(ReleaseMode.stop);
    clearPlayer.setReleaseMode(ReleaseMode.stop);
    _startGame();
  }

  @override
  void dispose() {
    _timer.cancel();
    grabPlayer.dispose();
    successPlayer.dispose();
    clearPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    endTime = DateTime.now().add(Duration(seconds: 25));
    _startTimer();
    _startNewSet();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = endTime.difference(now);
      if (diff.inSeconds <= 0) {
        _endGame();
      } else {
        setState(() {
          remainingSeconds = diff.inSeconds;
          remainingTimeRatio = remainingSeconds / 25;
        });
      }
    });
  }

  void _endGame() {
  _timer.cancel();
  _playClearSound();
  setState(() {
    isGameOver = true;
    isFading = false; // まだ白フェードは始めない
    final screenWidth = MediaQuery.of(context).size.width;
    confettiOffsets = List.generate(20, (_) => Random().nextDouble() * screenWidth);
  });

  // 1.2秒後に白フェード開始（紙吹雪が大体上に飛んだあたり）
  Future.delayed(Duration(milliseconds: 1200), () {
    if (mounted) {
      setState(() {
        isFading = true;
      });
    }
  });
}

  void _startNewSet() {
    final pool = [...allShapes]..shuffle();
    final selected = pool.sublist(0, 3);
    setState(() {
      draggableShapes = [...selected]..shuffle();
      targetShapes = [...selected]..shuffle();
      placedShapes = List.filled(3, null);
    });
  }

  Future<void> _playGrabSound() async => await grabPlayer.play(AssetSource('sounds/grab.wav'));
  Future<void> _playSuccessSound() async => await successPlayer.play(AssetSource('sounds/success.wav'));
  Future<void> _playClearSound() async => await clearPlayer.play(AssetSource('sounds/clear.wav'));

  void _handleSuccess(int index, String data) {
    setState(() {
      placedShapes[index] = data;
      _playSuccessSound();
      if (_checkCompletion()) {
        correctCount++;
        if (currentSet < totalSets && !isGameOver) {
          currentSet++;
          Future.delayed(Duration(milliseconds: 800), _startNewSet);
        }
      }
    });
  }

  bool _checkCompletion() => placedShapes.every((s) => s != null);

  Widget _buildDraggable(String shape) {
    return Draggable<String>(
      data: shape,
      onDragStarted: _playGrabSound,
      feedback: _buildShapeImage(shape, 80, glow: true),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildShapeImage(shape, 60),
      ),
      child: _buildShapeImage(shape, 60),
    );
  }

  Widget _buildDragTarget(int index) {
    String shape = draggableShapes[index];
    String? placed = placedShapes[index];
    bool isCorrect = placed == shape;

    return DragTarget<String>(
      onWillAccept: (data) => data == shape,
      onAccept: (data) => _handleSuccess(index, data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 80,
          height: 80,
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400, width: 3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isCorrect
                ? [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.7),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: placed != null
              ? _buildShapeImage(placed, 70, glow: true)
              : Image.asset(
                  'assets/images/silhouette/$shape.png',
                  width: 70,
                  height: 70,
                ),
        );
      },
    );
  }

  Widget _buildShapeImage(String shape, double size, {bool glow = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 6,
                ),
              ]
            : [],
      ),
      child: Image.asset('assets/images/$shape.png', width: size, height: size),
    );
  }

  Widget _buildConfettiShape(String shape, double leftOffset) {
    final double size = 20 + Random().nextDouble() * 40;
    final double dx = (Random().nextDouble() - 0.5) * 300; // 左右にバラける
    final double dy = -500 - Random().nextDouble() * 200;  // -500〜-700ピクセル上へ
// 上に向かって飛ぶ

    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: Offset.zero, end: Offset(dx, dy)),
      duration: Duration(milliseconds: 1200 + Random().nextInt(800)),
      curve: Curves.easeOut,
      builder: (context, Offset offset, _) {
        final double opacity = (1 - offset.distance / 400).clamp(0.0, 1.0);
        if (opacity <= 0.0) {
          return SizedBox.shrink(); // 透明なら描画しない
        }
        return Positioned(
          left: leftOffset,
          bottom: 80,
          child: Transform.translate(
            offset: offset,
            child: Opacity(
              opacity: opacity,
              child: _buildShapeImage(shape, size),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // コンフェッティ表示
            ...confettiOffsets.map(
              (offset) => _buildConfettiShape(
                draggableShapes[Random().nextInt(draggableShapes.length)],
                offset,
              ),
            ),

            // フェード用白いオーバーレイ
            AnimatedOpacity(
              opacity: isFading ? 1.0 : 0.0,
              duration: Duration(seconds: 2),
              child: Container(color: Colors.white),
            ),

            // 文字とボタンは常に表示（フェードは背景だけ）
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
  correctCount >= 5 ? 'おめでとう！' : 'がんばったね！',
  style: TextStyle(
    fontSize: 36,
    color: Colors.orange,
    fontFamily: 'MochiyPop', // pubspec.yaml の family と一致
  ),
),


                  SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => TimeAttackHome()),
                          );
                        },
                        child: Text('もういちどあそぶ'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => HomeScreen()),
                            (route) => false,
                          );
                        },
                        child: Text('メニューにもどる'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 通常ゲーム画面
    return Scaffold(
      appBar: AppBar(
        title: Text('タイムアタック'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('残り: $remainingSeconds秒'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 14,
                  width: MediaQuery.of(context).size.width * remainingTimeRatio,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: draggableShapes
                  .where((s) => !placedShapes.contains(s))
                  .map(_buildDraggable)
                  .toList(),
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => _buildDragTarget(i)),
            ),
          ),
        ],
      ),
    );
  }
}
