import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final List<Widget> tabs;
  final int selectedIndex;
  final Function(int) onTabTapped;

  const Footer({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: tabs
          .map((tab) => BottomNavigationBarItem(
                icon: tab,
                label: '',
              ))
          .toList(),
      currentIndex: selectedIndex,
      onTap: onTabTapped,
    );
  }
}
