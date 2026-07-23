import 'package:flutter/material.dart';
import 'package:alamode_app/main.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 52,
      title: ValueListenableBuilder<int>(
        valueListenable: themeNotifier,
        builder: (context, themeIndex, _) {
          final key = appThemes[themeIndex]['key'] as String;
          return Image.asset(
            'assets/images/logo/$key.png',
            height: 44,
          );
        },
      ),
      centerTitle: true,
    );
  }
}
