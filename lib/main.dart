import 'package:flutter/material.dart';
import 'package:alamode_app/view/home.dart';
import 'package:alamode_app/view/favorite.dart';
import 'package:alamode_app/view/memo.dart';
import 'package:alamode_app/view/user.dart';
import 'package:alamode_app/widgets/header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1C6ECD);
  static const Color secondryColor = Color(0xFFEDEE9E);
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'ア・ラ・モード a la mode',
      theme: appTheme,
      home: MainApp(),
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
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.blackLight.withOpacity(0.7),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PinyonScript',
                fontSize: 18,
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.blackLight.withOpacity(0.7),
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
