// === lib/main.dart ===
import 'package:flutter/material.dart';
import 'mode_selection_screen.dart';

void main() {
  runApp(ShapeGameLauncher());
}

class ShapeGameLauncher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'かたちあそび',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: HomeScreen(), // ← ここで HomeScreen を呼び出す
    );
  }
}

// 💡 ここを追加：HomeScreen クラスの定義
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModeSelectionScreen();
  }
}
