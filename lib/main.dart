import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alamode_app/view/home.dart';
import 'package:alamode_app/view/favorite.dart';
import 'package:alamode_app/view/memo.dart';
import 'package:alamode_app/view/user.dart';
import 'package:alamode_app/widgets/header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// テーマ定義
const List<Map<String, dynamic>> appThemes = [
  {'key': 'blue', 'name': '花束に添えて', 'color': Color(0xFF1C6ECD)},
  {'key': 'pink', 'name': '愛と知る', 'color': Color(0xFFE8629A)},
  {'key': 'gold', 'name': 'オン・ユア・サイド', 'color': Color(0xFFcfb346)},
  {'key': 'green', 'name': '季節の待ち合わせ', 'color': Color(0xFFc9d406)},
];

final ValueNotifier<int> themeNotifier = ValueNotifier<int>(0);

class AppColors {
  static const Color primaryColor = Color(0xFF1C6ECD);
  static const Color blackDark = Color(0xFF1A1A1A);
  static const Color blackLight = Color(0xFF808080);
  static const Color greyDark = Color(0xFFCCCCCC);
  static const Color greyMedium = Color(0xFFE6E6E6);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFB9727C);
  static const Color favoriteColor = Color(0xFFB9727C);
  static const Color starColor = Colors.amber;
  static const Color inputBorderColor = Color(0xFFB8B8B8);
  static const Color inputFocusColor = primaryColor;
  static const Color dialogBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static const Color shadowColor = Color(0x1A000000);
  static const Color warmWhite = Color(0xFFFAF9F7); // 温かみのある白
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final corinthia = FontLoader('Corinthia')
    ..addFont(rootBundle.load('assets/fonts/Corinthia/Corinthia-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Corinthia/Corinthia-Bold.ttf'));
  await corinthia.load();

  final pinyon = FontLoader('PinyonScript')
    ..addFont(
        rootBundle.load('assets/fonts/Pinyon_Script/PinyonScript-Regular.ttf'));
  await pinyon.load();

  final prefs = await SharedPreferences.getInstance();
  final savedKey = prefs.getString('theme_key') ?? 'blue';
  themeNotifier.value =
      appThemes.indexWhere((t) => t['key'] == savedKey).clamp(0, 3);

  await Supabase.initialize(
    url: 'https://bdmtimgiqtcximckagle.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkbXRpbWdpcXRjeGltY2thZ2xlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk5NTkwNDAsImV4cCI6MjA4NTUzNTA0MH0.rolHffP2nRWabyhuJxN4Vsx7uuxaYRpaDXpcpGQ0xUw',
  );
  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeData appTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFFFAF9F7),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.blackDark),
      titleTextStyle: TextStyle(
        fontFamily: 'ZenMaruGothic',
        color: AppColors.blackDark,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamily: 'ZenMaruGothic',
        color: AppColors.blackDark,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'ZenMaruGothic',
        color: AppColors.blackDark,
      ),
      titleLarge: TextStyle(
        fontFamily: 'PlayfairDisplay',
        color: AppColors.blackDark,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      primary: AppColors.primaryColor,
      error: AppColors.errorColor,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryColor,
    ),
    fontFamily: 'ZenMaruGothic',
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeNotifier,
      builder: (context, themeIndex, _) {
        final primaryColor = appThemes[themeIndex]['color'] as Color;
        return MaterialApp(
          title: 'ア・ラ・モード a la mode',
          theme: appTheme.copyWith(
            primaryColor: primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              error: AppColors.errorColor,
              brightness: Brightness.light,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            progressIndicatorTheme:
                ProgressIndicatorThemeData(color: primaryColor),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
          ),
          home: MainApp(),
        );
      },
    );
  }
}

Widget buildStarRating(BuildContext context, num rating) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      return Icon(
        Icons.star_rounded,
        color: index < rating
            ? AppColors.starColor
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      );
    }),
  );
}

class AdUtils {
  static int calculateListItemCount(int itemCount) {
    if (itemCount <= 3) return itemCount;
    return itemCount + ((itemCount - 1) ~/ 3);
  }

  static bool shouldShowAdAt(int index) {
    return index > 0 && (index + 1) % 4 == 0;
  }

  static int getActualItemIndex(int listIndex) {
    final adCount = (listIndex) ~/ 4;
    return listIndex - adCount;
  }

  static Widget buildAdBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.greyMedium.withOpacity(0.8),
        border: Border.all(color: AppColors.greyMedium, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withOpacity(0.8),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.greyLight, AppColors.greyMedium],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ads_click, color: AppColors.blackLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'スポンサード',
                    style: TextStyle(
                      color: AppColors.blackLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.greyDark,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '広告',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  final PresentManagementService presentService = PresentManagementService();
  MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: _getSelectedScreen(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
                color: AppColors.greyMedium.withOpacity(0.6), width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFooterIconWithText(Icons.search_rounded, "Search", 0),
            _buildFooterIconWithText(Icons.favorite_rounded, "Fav", 1),
            _buildFooterIconWithText(Icons.edit_rounded, "Memo", 2),
            _buildFooterIconWithText(Icons.settings_rounded, "Setting", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterIconWithText(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 25,
              color:
                  isSelected ? primary : AppColors.blackLight.withOpacity(0.6),
            ),
            const SizedBox(height: 0),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PinyonScript',
                fontSize: 22,
                color: isSelected
                    ? primary
                    : AppColors.blackLight.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FavoriteScreen();
      case 2:
        return PresentList(
          presentService: widget.presentService,
        );
      case 3:
        return const UserScreen();
      default:
        return Container();
    }
  }
}
