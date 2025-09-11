import 'package:flutter/material.dart';
import 'package:alamode_app/view/home.dart';
import 'package:alamode_app/view/favorite.dart';
import 'package:alamode_app/view/present.dart';
import 'package:alamode_app/view/treat.dart';
import 'package:alamode_app/view/user.dart';
import 'package:alamode_app/widgets/header.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeData appTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
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
        fontFamily: 'ZenMaruGothic',
        color: AppColors.blackDark,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.blackDark,
      ),
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
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFooterIconWithText(Icons.search, "Search", 0),
            _buildFooterIconWithText(Icons.favorite, "Fav", 1),
            _buildFooterIconWithText(Icons.edit, "Present", 2),
            _buildFooterIconWithText(Icons.local_cafe, "Treat", 3),
            _buildFooterIconWithText(Icons.settings, "Setting", 4),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterIconWithText(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index
                ? AppColors.primaryColor
                : AppColors.blackLight.withOpacity(0.8),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Corinthia',
              fontSize: 12,
              color: _selectedIndex == index
                  ? AppColors.primaryColor
                  : AppColors.blackLight.withOpacity(0.8),
            ),
          ),
        ],
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
        return const TreatScreen();
      case 4:
        return const UserScreen();
      default:
        return Container();
    }
  }
}
