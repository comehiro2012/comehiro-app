import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'first_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseの初期化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 念のため、初期化が完全に完了するまで一瞬だけ安全マージンを取る記述です
  await Future.delayed(const Duration(milliseconds: 500));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'こめひろ店頭予約システム',
      debugShowCheckedModeBanner: false,
      // 日本語化の設定
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP')],
      theme: ThemeData(
        useMaterial3: true,
        // 全体のテーマカラー
        colorSchemeSeed: const Color.fromARGB(255, 206, 166, 151),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 206, 166, 151),
          foregroundColor: Colors.black,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      // アプリ起動時は最初のページ（FirstPage）を表示する
      home: const FirstPage(),
    );
  }
}
