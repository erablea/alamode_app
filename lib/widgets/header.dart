import 'package:alamode_app/main.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              'a la mode',
              style: TextStyle(
                fontFamily: 'PinyonScript',
                fontSize: 35,
                color: color,
                height: 0.9,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 29),
            child: Text(
              'ア・ラ・モード',
              style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontSize: 9,
                color: color,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }
}
