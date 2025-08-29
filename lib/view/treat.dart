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
    _loadMemoList();
    _checkSavedData(); // データの読み込み後に保存されたデータを確認
  }

  // メモ一覧を読み込む関数
  void _loadMemoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String memoListString = prefs.getString('memoList') ?? '[]';
    setState(() {
      _memoList =
          (json.decode(memoListString) as List).cast<Map<String, dynamic>>();
    });
  }

  // 新しいメモを保存する関数
  void _saveMemo(Map<String, dynamic> memo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String memoListString = prefs.getString('memoList') ?? '[]';
    List<dynamic> updatedMemoList = json.decode(memoListString);
    updatedMemoList.insert(0, memo);
    await prefs.setString('memoList', jsonEncode(updatedMemoList));

    // データの保存後に前の画面に戻る
    Navigator.pop(context);
  }

  void _checkSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String memoListString = prefs.getString('memoList') ?? '[]';
    List<dynamic> decodedList = json.decode(memoListString);
    print(decodedList); // 保存されたデータをコンソールに出力
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
