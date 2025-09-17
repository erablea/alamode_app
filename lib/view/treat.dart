import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TreatScreen extends StatefulWidget {
  const TreatScreen({Key? key}) : super(key: key);

  @override
  _TreatScreenState createState() => _TreatScreenState();
}

class _TreatScreenState extends State<TreatScreen> {
  List<Map<String, dynamic>> _memoList = [];

  // 初期化処理
  @override
  void initState() {
    super.initState();
  }

  // メインビルドメソッド
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize:
              const Size.fromHeight(kToolbarHeight - 8), // AppBarの高さを調整
          child: AppBar(title: null),
        ),
        body: Container(),
      ),
    );
  }
}
