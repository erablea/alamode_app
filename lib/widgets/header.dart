import 'package:alamode_app/main.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ア・ラ・モード',
            style: TextStyle(
              fontFamily: 'ZenMaruGothic',
              fontSize: 10,
              color: AppColors.primaryColor,
              letterSpacing: 2,
            ),
          ),
          Text(
            'a la mode',
            style: TextStyle(
              fontFamily: 'PinyonScript',
              fontSize: 30,
              color: AppColors.primaryColor,
              height: 0.9,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }
}
