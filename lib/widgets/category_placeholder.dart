import 'package:flutter/material.dart';

class CategoryPlaceholder extends StatelessWidget {
  final String? category;
  final double height;

  const CategoryPlaceholder({super.key, this.category, this.height = 110});

  static const _imageCategories = {
    'クッキー': 'assets/images/cookie.png',
    'ショコラ': 'assets/images/chocolat.png',
    '和菓子':   'assets/images/wagashi.png',
    '焼き菓子': 'assets/images/baked.png',
    'ゼリー・プリン': 'assets/images/pudding.png',
    'その他':   'assets/images/others.png',
  };

  static String getImagePath(String? category) =>
      _imageCategories[category] ?? 'assets/images/others.png';

  @override
  Widget build(BuildContext context) {
    final imagePath = getImagePath(category);
    return Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFFF5F5F3),
      child: Image.asset(imagePath, fit: BoxFit.contain),
    );
  }
}
