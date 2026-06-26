import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamode_app/main.dart';

// 12種類のアイコン定義（画像が揃ったら assets/icons/person_XX.png に差し替え予定）
const List<_PersonIconDef> kPersonIcons = [
  _PersonIconDef(0,  '🦄', Color(0xFFE8D5F5)), // ラベンダー
  _PersonIconDef(1,  '🦢', Color(0xFFB8E8F8)), // スカイブルー
  _PersonIconDef(2,  '🦋', Color(0xFFB0D8F8)), // クリアブルー
  _PersonIconDef(3,  '🧸', Color(0xFFEED8C0)), // ウォームベージュ
  _PersonIconDef(4,  '💐', Color(0xFFFFD8B8)), // オレンジクリーム
  _PersonIconDef(5,  '🌷', Color(0xFFFFC8D8)), // チューリップピンク
  _PersonIconDef(6,  '🌱', Color(0xFFB8F0D0)), // フレッシュミント
  _PersonIconDef(7,  '🍋', Color(0xFFFFF3B0)), // レモンイエロー
  _PersonIconDef(8,  '🍒', Color(0xFFF8A8B8)), // チェリーピンク
  _PersonIconDef(9,  '🍓', Color(0xFFFFB8CC)), // ストロベリーピンク
  _PersonIconDef(10, '🍰', Color(0xFFFCF4EC)), // ホワイトクリーム
  _PersonIconDef(11, '🕶️', Color(0xFFD8D8D8)), // グレー
  _PersonIconDef(12, '🩰', Color(0xFFFFD8E8)), // バレエピンク
  _PersonIconDef(13, '👒', Color(0xFFCCE8A0)), // 黄緑
  _PersonIconDef(14, '🫧', Color(0xFFA8E8F8)), // アクア
  _PersonIconDef(15, '🎀', Color(0xFFFFB0CC)), // ホットピンク
];

class _PersonIconDef {
  final int index;
  final String emoji;
  final Color bgColor;
  const _PersonIconDef(this.index, this.emoji, this.bgColor);
}

class PersonIconService {
  static const _prefKey = 'person_icons';

  static Future<Map<String, int>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveIconIndex(String personName, int iconIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadAll();
    current[personName] = iconIndex;
    await prefs.setString(_prefKey, jsonEncode(current));
  }

  static Future<int?> getIconIndex(String personName) async {
    final all = await loadAll();
    return all[personName];
  }
}

// アバター表示ウィジェット
class PersonAvatar extends StatefulWidget {
  final String personName;
  final double radius;
  final bool showEditBadge;

  const PersonAvatar({super.key, required this.personName, this.radius = 20, this.showEditBadge = false});

  @override
  State<PersonAvatar> createState() => _PersonAvatarState();
}

class _PersonAvatarState extends State<PersonAvatar> {
  int? _iconIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PersonAvatar old) {
    super.didUpdateWidget(old);
    if (old.personName != widget.personName) _load();
  }

  Future<void> _load() async {
    final idx = await PersonIconService.getIconIndex(widget.personName);
    if (mounted) setState(() => _iconIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar(context);
    if (!widget.showEditBadge) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: -4,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.blackDark.withOpacity(0.65),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '編集',
              style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (_iconIndex != null && _iconIndex! >= 0 && _iconIndex! < kPersonIcons.length) {
      final def = kPersonIcons[_iconIndex!];
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: def.bgColor,
        child: Text(
          def.emoji,
          style: TextStyle(fontSize: widget.radius * 0.9),
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
      radius: widget.radius,
      child: Text(
        widget.personName.isNotEmpty ? widget.personName[0] : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: widget.radius * 0.8,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

// アイコン選択ポップアップ
class PersonIconPickerDialog extends StatefulWidget {
  final String personName;
  final int? currentIndex;

  const PersonIconPickerDialog({
    super.key,
    required this.personName,
    this.currentIndex,
  });

  @override
  State<PersonIconPickerDialog> createState() => _PersonIconPickerDialogState();
}

class _PersonIconPickerDialogState extends State<PersonIconPickerDialog> {
  late int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Dialog(
      backgroundColor: AppColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.personName} のアイコン',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.blackDark,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: kPersonIcons.length,
              itemBuilder: (context, i) {
                final def = kPersonIcons[i];
                final isSelected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: def.bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6)]
                          : null,
                    ),
                    child: Center(
                      child: Text(def.emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('キャンセル',
                      style: TextStyle(color: AppColors.blackLight)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedIndex == null
                      ? null
                      : () => Navigator.of(context).pop(_selectedIndex),
                  child: const Text('決定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
