import 'package:alamode_app/main.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'ア・ラ・モード',
              style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontSize: 10,
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              'a la mode',
              style: TextStyle(
                fontFamily: 'Corinthia',
                fontSize: 20,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
    );
  }
}
