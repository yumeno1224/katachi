import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'mode_selection_screen.dart';

class ShapeMatchGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ShapeMatchHome(),
    );
  }
}

class ShapeMatchHome extends StatefulWidget {
  @override
  _ShapeMatchHomeState createState() => _ShapeMatchHomeState();
}

class _ShapeMatchHomeState extends State<ShapeMatchHome> {
  // AudioPlayerとAudioCacheを用意
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');

  final List<String> shapePool = [
    'circle', 'circle', 'circle',
    'triangle', 'triangle', 'triangle',
    'square', 'square', 'square',
    'star', 'heart'
  ];

  List<String> draggableShapes = [];
  List<String> targetShapes = [];
  List<String?> placedShapes = List.filled(3, null);

  int currentSet = 1;
  final int totalSets = 3;
  bool showCongrats = false;
  bool showFloatingShapes = false;
  List<double> confettiOffsets = [];

  @override
  void initState() {
    super.initState();
    _audioCache.loadAll(['grab.wav', 'success.wav', 'clear.wav']);
    _startNewSet();
  }

  Future<void> _playSound(String filename) async {
    try {
      final url = await _audioCache.load(filename);
      await _audioPlayer.play(DeviceFileSource(url.path));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _startNewSet() {
    final allShapes = ['circle', 'triangle', 'square', 'star', 'heart'];
    allShapes.shuffle();
    final selectedShapes = allShapes.sublist(0, 3);

    setState(() {
      draggableShapes = [...selectedShapes]..shuffle();
      targetShapes = [...selectedShapes]..shuffle();
      placedShapes = List.filled(3, null);
    });
  }

  void _playGrabSound() => _playSound('grab.wav');
  void _playSuccessSound() => _playSound('success.wav');
  void _playClearSound() => _playSound('clear.wav');

  void _handleSuccess(int index, String data) {
  setState(() {
    placedShapes[index] = data;
    _playSuccessSound();

    if (_checkCompletion()) {
      if (currentSet < totalSets) {
        currentSet++;
        Future.delayed(Duration(seconds: 1), _startNewSet);
      } else {
        // 最後の図形がはまった瞬間の成功音をしっかり鳴らしてからクリア音
        Future.delayed(Duration(milliseconds: 600), () {
          _playClearSound();
          setState(() {
            showCongrats = true;
            showFloatingShapes = true;
            confettiOffsets = List.generate(
              20,
              (_) => Random().nextDouble() * MediaQuery.of(context).size.width,
            );
          });
        });
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
    final shape = draggableShapes[index];
    final placed = placedShapes[index];
    final isCorrect = placed == shape;

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
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: Offset(0, 0), end: Offset(0, -250)),
      duration: Duration(seconds: 3),
      curve: Curves.easeOut,
      builder: (context, Offset offset, _) {
        return Positioned(
          left: leftOffset,
          bottom: 100,
          child: Transform.translate(
            offset: offset,
            child: Opacity(
              opacity: 1 - offset.dy.abs() / 250,
              child: _buildShapeImage(shape, 40),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSets, (index) {
        Color color;
        if (showCongrats) {
          color = Colors.orange;
        } else if (index + 1 < currentSet) {
          color = Colors.orange;
        } else if (index + 1 == currentSet) {
          color = Colors.lightBlue;
        } else {
          color = Colors.grey;
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showCongrats) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            ...List.generate(confettiOffsets.length, (i) => _buildConfettiShape(draggableShapes[i % draggableShapes.length], confettiOffsets[i])),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
  'おめでとう！',
  style: TextStyle(
    fontSize: 36,
    color: Colors.orange,
    fontFamily: 'MochiyPop',
  ),
)
,
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentSet = 1;
                        showCongrats = false;
                        showFloatingShapes = false;
                        _startNewSet();
                      });
                    },
                    child: Text('もういちどあそぶ'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => ModeSelectionScreen()),
                        (route) => false,
                      );
                    },
                    child: Text('メニューにもどる'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('かんたんモード'),
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          _buildProgressIndicator(),
          SizedBox(height: 16),
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
