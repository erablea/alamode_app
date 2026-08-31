import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/widgets/category_placeholder.dart';
import 'package:alamode_app/widgets/person_icon.dart';
import 'package:alamode_app/view/memo.dart';
import 'package:alamode_app/view/auth.dart';
import 'package:alamode_app/view/legal.dart';
import 'package:alamode_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<String> _personList = [];
  List<Map<String, dynamic>> _allPresents = [];
  late PresentManagementService _presentService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _presentService = PresentManagementService();
    _loadPersonList();
  }

  Future<void> _loadPersonList() async {
    setState(() => _isLoading = true);
    try {
      _allPresents = await _presentService.getAllPresents();
      final uniquePersons = <String>{};
      for (final present in _allPresents) {
        final who = present['present_who'] as String?;
        if (who != null && who.isNotEmpty) {
          uniquePersons.add(who);
        }
      }

      setState(() {
        _personList = uniquePersons.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getPresentsForPerson(String person) {
    return _allPresents
        .where((present) => present['present_who'] == person)
        .toList();
  }

  void _showPersonDetails(String person) {
    final personPresents = _getPresentsForPerson(person);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.dialogBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ヘッダー部分
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final currentIndex =
                              await PersonIconService.getIconIndex(person);
                          if (!context.mounted) return;
                          final result = await showDialog<int>(
                            context: context,
                            builder: (_) => PersonIconPickerDialog(
                              personName: person,
                              currentIndex: currentIndex,
                            ),
                          );
                          if (result != null) {
                            await PersonIconService.saveIconIndex(
                                person, result);
                            if (!mounted) return;
                            setState(() {});
                          }
                        },
                        child: PersonAvatar(
                            personName: person,
                            radius: 22,
                            showEditBadge: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackDark,
                              ),
                            ),
                            Text(
                              '${personPresents.length}件のプレゼント',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.blackLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // コンテンツ部分
                Flexible(
                  child: personPresents.isEmpty
                      ? Container(
                          height: 200,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard_outlined,
                                size: 48,
                                color:
                                    AppColors.blackLight.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'まだプレゼントの記録がありません',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.blackLight
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: personPresents.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final present = personPresents[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowColor,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: AppColors.greyLight,
                                      ),
                                      child: present['present_imageurl'] != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CommonWidgets.buildImage(
                                                present['present_imageurl'],
                                                _presentService,
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CategoryPlaceholder(
                                                category:
                                                    present['present_genre'],
                                                height: 60,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            present['present_name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.blackDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (present['present_brand'] !=
                                                  null &&
                                              present['present_brand']
                                                  .toString()
                                                  .isNotEmpty)
                                            Text(
                                              present['present_brand'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.blackLight,
                                              ),
                                            ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                '¥${Utils.formatCurrency(present['present_price'])}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.blackDark,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: AppColors.blackLight,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                present['present_date'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.blackLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Text(
                                                '反応: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.blackLight,
                                                ),
                                              ),
                                              CommonWidgets.buildReactionStar(
                                                present['present_reaction'] ??
                                                    0,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                          if (present['present_memo'] != null &&
                                              present['present_memo']
                                                  .toString()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.greyLight,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                present['present_memo'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.blackLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // フッター部分
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.greyMedium, width: 1),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '閉じる',
                      style: TextStyle(
                        color: AppColors.blackDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定', style: TextStyle(fontSize: 18)),
        toolbarHeight: 40.0,
        flexibleSpace: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40.0,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/lace.png'),
                    repeat: ImageRepeat.repeatX,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildPersonListSection(),
                const SizedBox(height: 32),
                _buildAuthSection(),
                const SizedBox(height: 16),
                _buildSettingsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemePickerSheet() {
    return ValueListenableBuilder<int>(
      valueListenable: themeNotifier,
      builder: (context, currentIndex, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.greyDark,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('テーマカラー',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackDark)),
              const SizedBox(height: 16),
              ...List.generate(appThemes.length, (i) {
                final theme = appThemes[i];
                final isSelected = currentIndex == i;
                final color = theme['color'] as Color;
                return GestureDetector(
                  onTap: () async {
                    themeNotifier.value = i;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('theme_key', theme['key'] as String);
                    setState(() {});
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                        bottom: i < appThemes.length - 1 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.08)
                          : AppColors.greyLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 20,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Text(
                          theme['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? color : AppColors.blackDark,
                          ),
                        )),
                        if (isSelected)
                          Icon(Icons.check_circle, color: color, size: 18),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonListSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'お菓子を贈った人・貰った人一覧',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  ),
                )
              : _personList.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_add_outlined,
                              size: 48,
                              color:
                                  AppColors.blackLight.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'まだ記録がありません',
                              style: TextStyle(
                                color:
                                    AppColors.blackLight.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Memoタブからお菓子を記録すると、ここに表示されます',
                              style: TextStyle(
                                color:
                                    AppColors.blackLight.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: _personList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final person = entry.value;
                        final presentCount =
                            _getPresentsForPerson(person).length;
                        final isLast = index == _personList.length - 1;

                        return Container(
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : const Border(
                                    bottom: BorderSide(
                                      color: AppColors.greyMedium,
                                      width: 1,
                                    ),
                                  ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showPersonDetails(person),
                              borderRadius: isLast
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    )
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    PersonAvatar(
                                        personName: person, radius: 22),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            person,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppColors.blackDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$presentCount件のプレゼント',
                                            style: const TextStyle(
                                              color: AppColors.blackLight,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.greyLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: AppColors.blackLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildAuthSection() {
    final primary = Theme.of(context).primaryColor;
    final isLoggedIn = AuthService.instance.isLoggedIn;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      ),
      child: isLoggedIn
          ? _buildLoggedInTile(primary)
          : _buildLoggedOutTile(primary),
    );
  }

  Widget _buildLoggedInTile(Color primary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const MyPageScreen()));
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              FutureBuilder<int?>(
                future: () {
                  final uid = AuthService.instance.currentUser?.id;
                  return uid != null
                      ? PersonIconService.getSelfIconIndex(uid)
                      : Future.value(null);
                }(),
                builder: (context, snapshot) {
                  final iconIndex = snapshot.data;
                  if (iconIndex != null &&
                      iconIndex >= 0 &&
                      iconIndex < kPersonIcons.length) {
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kPersonIcons[iconIndex].bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(kPersonIcons[iconIndex].emoji,
                          style: const TextStyle(fontSize: 20)),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.account_circle_outlined,
                        color: primary, size: 20),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ログイン中',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.blackLight)),
                    FutureBuilder<String?>(
                      future: AuthService.instance.getUserName(),
                      builder: (context, snap) => Text(
                        snap.data ??
                            AuthService.instance.currentUser?.email ??
                            '',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _logout,
                child: const Text('ログアウト',
                    style:
                        TextStyle(color: AppColors.errorColor, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedOutTile(Color primary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _navigateToLogin,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.login, color: AppColors.blackDark, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ログイン / 新規登録',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackDark)),
                    SizedBox(height: 2),
                    Text('記録を端末間で引き継ぐことができます',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.blackLight)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.blackLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToLogin() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (loggedIn == true) {
      setState(() {});
      await _loadPersonList();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？\nログアウト後もローカルのデータは引き続き閲覧できます。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            child: const Text('ログアウト',
                style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        setState(() {});
        await _loadPersonList();
      }
    }
  }

  Widget _buildSettingsSection() {
    final settingsItems = [
      {
        'title': 'テーマカラー',
        'icon': Icons.palette_outlined,
      },
      {
        'title': 'アプリについて',
        'icon': Icons.info_outline,
      },
      {
        'title': 'お問い合わせ',
        'icon': Icons.contact_support_outlined,
      },
      {
        'title': '運営会社・利用規約',
        'icon': Icons.business_outlined,
      },
      {
        'title': 'プライバシーポリシー',
        'icon': Icons.privacy_tip_outlined,
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: settingsItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == settingsItems.length - 1;

          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(
                        color: AppColors.greyMedium,
                        width: 1,
                      ),
                    ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToInfoScreen(item['title'] as String),
                borderRadius: index == 0
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      )
                    : isLast
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          )
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: AppColors.blackDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blackDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.blackLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToInfoScreen(String title) {
    if (title == 'テーマカラー') {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.dialogBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _buildThemePickerSheet(),
      );
      return;
    }

    Widget screen;

    switch (title) {
      case 'アプリについて':
        screen = _buildAboutScreen();
        break;
      case 'お問い合わせ':
        screen = _buildContactScreen();
        break;
      case '運営会社・利用規約':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const TermsScreen()));
        return;
      case 'プライバシーポリシー':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
        return;
      default:
        screen = Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(child: Text('Coming soon')),
        );
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildInfoScreen(
      {required String title, required List<Widget> content}) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutScreen() {
    return _buildInfoScreen(
      title: 'アプリについて',
      content: [
        const Text(
          '「ア・ラ・モード」',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blackDark,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: const Text(
            '「今年の帰省は何のお土産を持って行こう？ 前回は何を贈ったのだったっけ？」「この前食べたあのお菓子、とっても美味しかったけど、似たお菓子を開拓したいなぁ」\n\n'
            'このアプリは、大切な人への贈り物や、自分にとってのご褒美を記録するために作られました。\n\n'
            '「ア・ラ・モード」は、フランス語で「流行の」「おしゃれな」という意味。日本では「プリン・ア・ラ・モード」を思い浮かべる人が多いと思います。\n'
            'たくさんのキラキラしたお菓子を、一つのお皿にギュッと詰め込んだアプリにしたいという想いから名前をつけました。\n\n'
            'これからも皆様に使いやすく気に入っていただけるアプリになるよう、アップデートして参ります。',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.blackDark,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // イラスト挿入予定
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '主な機能',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blackDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(context, Icons.search, '商品検索',
            'おすすめ商品を編集部が随時更新しています。お気に入りをして、贈り物やご褒美の参考にできます'),
        _buildFeatureItem(
            context, Icons.edit, '反応や評価を記録', 'Memoタブから贈った時の反応や自己評価を5段階で記録できます'),
        _buildFeatureItem(context, Icons.people_outline, '人別管理',
            'Memoタブで記録すると、贈った人・貰った人ごとに履歴を管理できます'),
      ],
    );
  }

  Widget _buildContactScreen() {
    return _buildInfoScreen(
      title: 'お問い合わせ',
      content: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.contact_support,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'お問い合わせ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ContactFormWidget(),
      ],
    );
  }
}

class _ErrorReportItem {
  String? selectedSweet;
  String? selectedErrorType;
  final TextEditingController correctContentController =
      TextEditingController();
  Map<String, dynamic>? currentSweetData;
  void dispose() {
    correctContentController.dispose();
  }
}

class _ContactFormWidget extends StatefulWidget {
  @override
  _ContactFormWidgetState createState() => _ContactFormWidgetState();
}

class _ContactFormWidgetState extends State<_ContactFormWidget> {
  int _expandedSection = -1;

  // 情報の間違い報告用
  List<_ErrorReportItem> _errorReportItems = [_ErrorReportItem()];

  // アプリの不具合報告用
  final TextEditingController _bugReportController = TextEditingController();

  // その他問い合わせ用
  final TextEditingController _otherNameController = TextEditingController();
  final TextEditingController _otherEmailController = TextEditingController();
  final TextEditingController _otherInquiryController = TextEditingController();

  // 企業様用
  final TextEditingController _businessCompanyController =
      TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessEmailController =
      TextEditingController();
  final TextEditingController _businessController = TextEditingController();

  // スパム対策用ハニーポット（人間には見えない項目。ここに値が入っていたら
  // ボットとみなして送信を握りつぶす）。
  final TextEditingController _honeypotController = TextEditingController();

  @override
  void dispose() {
    _bugReportController.dispose();
    _otherNameController.dispose();
    _otherEmailController.dispose();
    _otherInquiryController.dispose();
    _businessCompanyController.dispose();
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _businessController.dispose();
    _honeypotController.dispose();
    for (var item in _errorReportItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildExpandableSection(
          index: 0,
          title: '情報の間違い報告',
          icon: Icons.error_outline,
          content: _buildErrorReportContent(),
        ),
        const SizedBox(height: 16),
        _buildExpandableSection(
          index: 1,
          title: 'アプリの不具合報告',
          icon: Icons.bug_report_outlined,
          content: _buildBugReportContent(),
        ),
        const SizedBox(height: 16),
        _buildExpandableSection(
          index: 2,
          title: 'その他問い合わせ',
          icon: Icons.help_outline,
          content: _buildOtherInquiryContent(),
        ),
        const SizedBox(height: 16),
        _buildExpandableSection(
          index: 3,
          title: '企業様',
          icon: Icons.business_outlined,
          content: _buildBusinessContent(),
        ),
        // スパム対策用ハニーポット。人間の目には触れないが、フォームを
        // 機械的に全項目埋めるタイプのボットには見えてしまう項目。
        ExcludeSemantics(
          child: Opacity(
            opacity: 0,
            child: SizedBox(
              height: 0,
              width: 0,
              child: TextField(
                controller: _honeypotController,
                autofocus: false,
                decoration: const InputDecoration(labelText: 'website'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required int index,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final isExpanded = _expandedSection == index;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyMedium),
        boxShadow: [
          if (isExpanded)
            const BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedSection = isExpanded ? -1 : index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.blackDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blackDark,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0.0,
                      child: const Icon(
                        Icons.expand_more,
                        color: AppColors.blackLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isExpanded ? 1.0 : 0.0,
              child: isExpanded
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.greyMedium),
                        ),
                      ),
                      child: content,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorReportContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...List.generate(_errorReportItems.length, (index) {
          return Column(
            children: [
              _buildErrorReportItem(index),
              if (index < _errorReportItems.length - 1)
                const SizedBox(height: 16),
            ],
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addErrorReportItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('項目を追加'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blackDark,
                  side: const BorderSide(color: AppColors.greyMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_errorReportItems.length > 1) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _removeErrorReportItem,
                icon: const Icon(Icons.remove, size: 18),
                label: const Text('項目を削除'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorColor,
                  side: const BorderSide(color: AppColors.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _buildSendButton(() => _sendErrorReport()),
      ],
    );
  }

  Widget _buildErrorReportItem(int index) {
    final item = _errorReportItems[index];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorReportItems.length > 1)
            Text(
              '項目 ${index + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.blackDark,
              ),
            ),
          if (_errorReportItems.length > 1) const SizedBox(height: 12),

          // お菓子名選択
          const Text(
            'お菓子名 *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.blackLight,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showSweetSearchDialog(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border.all(color: AppColors.inputBorderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.selectedSweet?.isNotEmpty == true
                          ? item.selectedSweet!
                          : 'お菓子を選択してください',
                      style: TextStyle(
                        fontSize: 16,
                        color: item.selectedSweet?.isNotEmpty == true
                            ? AppColors.blackDark
                            : AppColors.blackLight,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.search,
                    color: AppColors.blackLight,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 間違っている内容
          const Text(
            '間違っている内容 *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.blackLight,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: item.selectedErrorType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
            items: const [
              DropdownMenuItem(value: 'お菓子名', child: Text('お菓子名')),
              DropdownMenuItem(value: '会社名', child: Text('会社名')),
              DropdownMenuItem(value: '画像', child: Text('画像')),
              DropdownMenuItem(value: 'カテゴリー', child: Text('カテゴリー')),
              DropdownMenuItem(value: '金額', child: Text('金額')),
              DropdownMenuItem(value: '賞味期限', child: Text('賞味期限')),
              DropdownMenuItem(value: '個包装', child: Text('個包装')),
              DropdownMenuItem(value: '常温', child: Text('常温')),
              DropdownMenuItem(value: 'オンライン購入', child: Text('オンライン購入')),
              DropdownMenuItem(value: '商品説明', child: Text('商品説明')),
              DropdownMenuItem(value: 'URLリンク', child: Text('URLリンク')),
            ],
            onChanged: (value) {
              setState(() {
                item.selectedErrorType = value;
              });
            },
          ),
          if (item.selectedErrorType != null &&
              item.currentSweetData != null) ...[
            const SizedBox(height: 16),
            const Text(
              '現在のデータ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.blackLight,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                border: Border.all(color: AppColors.greyMedium),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getCurrentDataText(
                    item.selectedErrorType!, item.currentSweetData!),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.blackDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Icon(
                Icons.arrow_downward,
                color: AppColors.blackLight,
                size: 24,
              ),
            ),
          ],
          _buildLabeledField(
            label: '正しい内容 *',
            controller: item.correctContentController,
            hintText: '正しい内容を入力してください',
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  String _getCurrentDataText(String errorType, Map<String, dynamic> sweetData) {
    switch (errorType) {
      case 'お菓子名':
        return sweetData['item_name'] ?? '不明';
      case '会社名':
        return sweetData['_brandCompany'] ?? '不明';
      case 'カテゴリー':
        return sweetData['item_category'] ?? '不明';
      case '金額':
        return '¥${Utils.formatCurrency(sweetData['item_price10percent'])}';
      case '賞味期限':
        final expiry = sweetData['item_expirydate'];
        return expiry != null ? '$expiry日' : '不明';
      case '個包装':
        return sweetData['item_individualwrapping'] == true ? 'あり' : 'なし';
      case '常温':
        return sweetData['item_roomtemperature'] == true ? '常温保存可能' : '要冷蔵・冷凍';
      case 'オンライン購入':
        return sweetData['item_online'] == true ? '購入可能' : '購入不可';
      case '商品説明':
        return sweetData['item_description'] ?? '説明なし';
      case 'URLリンク':
        return sweetData['item_url'] ?? 'URLなし';
      default:
        return '不明';
    }
  }

  Widget _buildBugReportContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildLabeledField(
          label: '不具合の内容 *',
          controller: _bugReportController,
          hintText: '不具合の詳細を入力してください',
          maxLines: 5,
          minLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: 24),
        _buildSendButton(() => _sendBugReport()),
      ],
    );
  }

  Widget _buildOtherInquiryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'お名前 *',
          controller: _otherNameController,
          maxLength: 30,
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'メールアドレス *',
          controller: _otherEmailController,
          keyboardType: TextInputType.emailAddress,
          maxLength: 100,
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'お問い合わせ内容 *',
          controller: _otherInquiryController,
          hintText: 'お問い合わせ内容を入力してください',
          maxLines: 5,
          minLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: 16),
        _buildContactDisclaimer(),
        const SizedBox(height: 24),
        _buildSendButton(() => _sendOtherInquiry()),
      ],
    );
  }

  Widget _buildBusinessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildLabeledField(
          label: '会社名 *',
          controller: _businessCompanyController,
          maxLength: 30,
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'ご担当者名 *',
          controller: _businessNameController,
          maxLength: 30,
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'メールアドレス *',
          controller: _businessEmailController,
          keyboardType: TextInputType.emailAddress,
          maxLength: 100,
        ),
        const SizedBox(height: 16),
        _buildLabeledField(
          label: 'お問い合わせ内容 *',
          controller: _businessController,
          hintText: '企業様からの商品情報提供や宣伝のご活用お待ちしております。内容を入力してください',
          maxLines: 5,
          minLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: 16),
        _buildContactDisclaimer(),
        const SizedBox(height: 24),
        _buildSendButton(() => _sendBusinessInquiry()),
      ],
    );
  }

  Widget _buildSendButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: AppColors.blackDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
          shadowColor: AppColors.shadowColor,
        ),
        child: const Text(
          '送信',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          style: const TextStyle(color: AppColors.blackLight),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.inputFocusColor, width: 2),
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
            hintText: hintText,
          ),
        ),
      ],
    );
  }

  Widget _buildContactDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyMedium),
      ),
      child: Text(
        '本アプリは${DateTime.now().year}年現在、個人が運営しております。お問い合わせに対する返信は必ず行われるものではございませんので、ご了承ください。',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.blackLight,
          height: 1.5,
        ),
      ),
    );
  }

  void _addErrorReportItem() {
    setState(() {
      _errorReportItems.add(_ErrorReportItem());
    });
  }

  void _removeErrorReportItem() {
    if (_errorReportItems.length > 1) {
      setState(() {
        final removedItem = _errorReportItems.removeLast();
        removedItem.dispose();
      });
    }
  }

  void _showSweetSearchDialog(int itemIndex) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ItemSearchDialog(searchType: SearchType.name),
    );

    if (result != null) {
      setState(() {
        _errorReportItems[itemIndex].selectedSweet = result['item_name'] ?? '';
        _errorReportItems[itemIndex].currentSweetData = result;
      });
    }
  }

  void _sendErrorReport() async {
    // バリデーション
    bool hasError = false;
    for (var item in _errorReportItems) {
      if (item.selectedSweet?.isEmpty != false ||
          item.selectedErrorType?.isEmpty != false ||
          item.correctContentController.text.isEmpty) {
        hasError = true;
        break;
      }
    }

    if (hasError) {
      _showValidationError('すべての必須項目を入力してください。');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: '情報の間違い報告',
      content: _buildErrorReportConfirmation(),
    );

    if (confirmed) {
      await _submitInquiry(
        type: 'error_report',
        content: _buildErrorReportEmailBody(),
      );
    }
  }

  void _sendBugReport() async {
    if (_bugReportController.text.isEmpty) {
      _showValidationError('不具合の内容を入力してください。');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'アプリの不具合報告',
      content: Text('不具合内容：\n${_bugReportController.text}'),
    );

    if (confirmed) {
      await _submitInquiry(
        type: 'bug_report',
        content: '不具合の内容：\n${_bugReportController.text}',
      );
    }
  }

  void _sendOtherInquiry() async {
    if (_otherNameController.text.isEmpty ||
        _otherEmailController.text.isEmpty ||
        _otherInquiryController.text.isEmpty) {
      _showValidationError('すべての必須項目を入力してください。');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'その他問い合わせ',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('お名前：${_otherNameController.text}'),
          Text('メールアドレス：${_otherEmailController.text}'),
          Text('お問い合わせ内容：\n${_otherInquiryController.text}'),
        ],
      ),
    );

    if (confirmed) {
      await _submitInquiry(
        type: 'other',
        name: _otherNameController.text,
        email: _otherEmailController.text,
        content: _otherInquiryController.text,
      );
    }
  }

  void _sendBusinessInquiry() async {
    if (_businessCompanyController.text.isEmpty ||
        _businessNameController.text.isEmpty ||
        _businessEmailController.text.isEmpty ||
        _businessController.text.isEmpty) {
      _showValidationError('すべての必須項目を入力してください。');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: '企業様からのお問い合わせ',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('会社名：${_businessCompanyController.text}'),
          Text('ご担当者名：${_businessNameController.text}'),
          Text('メールアドレス：${_businessEmailController.text}'),
          Text('お問い合わせ内容：\n${_businessController.text}'),
        ],
      ),
    );

    if (confirmed) {
      await _submitInquiry(
        type: 'business',
        company: _businessCompanyController.text,
        name: _businessNameController.text,
        email: _businessEmailController.text,
        content: _businessController.text,
      );
    }
  }

  Widget _buildErrorReportConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._errorReportItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorReportItems.length > 1)
                Text(
                  '項目 ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              Text('お菓子名：${item.selectedSweet}'),
              Text('間違っている内容：${item.selectedErrorType}'),
              Text('正しい内容：${item.correctContentController.text}'),
              if (index < _errorReportItems.length - 1)
                const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }

  String _buildErrorReportEmailBody() {
    final buffer = StringBuffer();
    buffer.writeln('情報の間違い報告');
    buffer.writeln('');

    for (int i = 0; i < _errorReportItems.length; i++) {
      final item = _errorReportItems[i];
      if (_errorReportItems.length > 1) {
        buffer.writeln('項目 ${i + 1}：');
      }
      buffer.writeln('お菓子名：${item.selectedSweet}');
      buffer.writeln('間違っている内容：${item.selectedErrorType}');
      buffer.writeln('正しい内容：${item.correctContentController.text}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required Widget content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.dialogBackground,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              title,
              style: const TextStyle(
                color: AppColors.blackDark,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(child: content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'キャンセル',
                  style: TextStyle(color: AppColors.blackLight),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: AppColors.blackDark,
                ),
                child: const Text(
                  '送信',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _isNetworkError(String error) {
    const patterns = [
      'SocketException',
      'Failed to fetch',
      'ClientException',
      'Connection failed',
      'Connection refused',
      'Failed host lookup',
      'Network is unreachable',
      'TimeoutException',
      'XMLHttpRequest',
    ];
    return patterns.any((p) => error.contains(p));
  }

  static const _inquiryCooldownSeconds = 60;
  static const _lastInquirySubmitKey = 'last_inquiry_submit_ms';

  Future<void> _submitInquiry({
    required String type,
    required String content,
    String? name,
    String? email,
    String? company,
  }) async {
    // ハニーポットに値が入っていればボットとみなし、送信したように見せて
    // 実際には何もしない（ボットに気づかれて手口を変えられるのを避けるため）。
    if (_honeypotController.text.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('送信しました。内容によっては返信が届かない場合がございます。'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _clearForm();
      setState(() => _expandedSection = -1);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSubmitMs = prefs.getInt(_lastInquirySubmitKey);
    if (lastSubmitMs != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastSubmitMs;
      final remaining = _inquiryCooldownSeconds - elapsed ~/ 1000;
      if (remaining > 0) {
        if (!mounted) return;
        _showValidationError('連続送信を防ぐため、しばらく待ってから再度お試しください（あと$remaining秒）。');
        return;
      }
    }

    try {
      await supabase.from('inquiry').insert({
        'inquiry_type': type,
        'inquiry_name': name,
        'inquiry_email': email,
        'inquiry_company': company,
        'inquiry_content': content,
        'user_id':
            AuthService.instance.isLoggedIn ? AuthService.instance.userId : null,
      });
      await prefs.setInt(
          _lastInquirySubmitKey, DateTime.now().millisecondsSinceEpoch);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('送信しました。内容によっては返信が届かない場合がございます。'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _clearForm();
      setState(() => _expandedSection = -1);
    } catch (e) {
      if (!mounted) return;
      final message = _isNetworkError(e.toString())
          ? 'ネットワークに接続できません。通信環境をご確認のうえ、もう一度お試しください。'
          : '送信に失敗しました: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearForm() {
    // エラー報告フォームをクリア
    for (var item in _errorReportItems) {
      item.dispose();
    }
    _errorReportItems = [_ErrorReportItem()];

    // その他のフォームをクリア
    _bugReportController.clear();
    _otherNameController.clear();
    _otherEmailController.clear();
    _otherInquiryController.clear();
    _businessCompanyController.clear();
    _businessNameController.clear();
    _businessEmailController.clear();
    _businessController.clear();
    _honeypotController.clear();
  }
}

Widget _buildFeatureItem(
    BuildContext context, IconData icon, String title, String description) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.greyLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.greyMedium),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.blackLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _nameCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  String? _email;
  String? _gender;
  DateTime? _birthday;
  int? _iconIndex;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    _userId = user.id;
    _email = user.email;
    try {
      final profile = await AuthService.instance.getUserProfile();
      _nameCtrl.text = profile?['user_name'] ?? '';
      _gender = profile?['user_gender'];
      final bday = profile?['user_birthday'];
      if (bday != null) _birthday = DateTime.tryParse(bday);
    } catch (_) {
      // 読み込みに失敗した場合、空欄のまま保存できてしまうと既存データを
      // 空で上書きしてしまうため、保存ボタンを無効化してユーザーに知らせる。
      _loadFailed = true;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('プロフィールの読み込みに失敗しました。再度開き直してください。')),
            );
          }
        });
      }
    }
    final prefs = await SharedPreferences.getInstance();
    _iconIndex = prefs.getInt('user_profile_icon_${_userId}');
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final uid = _userId!;
      await supabase.from('user').update({
        'user_name': _nameCtrl.text.trim(),
        'user_gender': _gender,
        'user_birthday': _birthday?.toIso8601String().substring(0, 10),
        'user_update': DateTime.now().toIso8601String(),
      }).eq('user_id', uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('保存しました'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('保存に失敗しました: $e'),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _checkDailyLimit(String key) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('${key}_$dateStr') ?? 0;
    if (count >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('本日の変更上限（3回）に達しました'),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating),
        );
      }
      return false;
    }
    await prefs.setInt('${key}_$dateStr', count + 1);
    return true;
  }

  Future<void> _changeEmail() async {
    if (!await _checkDailyLimit('email_change')) return;
    if (!mounted) return;
    final ctrl = TextEditingController();
    final primary = Theme.of(context).primaryColor;
    final newEmail = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('メールアドレス変更'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: '新しいメールアドレス',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primary, width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_), child: const Text('キャンセル')),
          ElevatedButton(
              onPressed: () => Navigator.pop(_, ctrl.text.trim()),
              child: const Text('変更')),
        ],
      ),
    );
    ctrl.dispose();
    if (newEmail == null || newEmail.isEmpty) return;
    try {
      await supabase.auth.updateUser(UserAttributes(email: newEmail));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('確認メールを送信しました'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('変更に失敗しました: $e'),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!await _checkDailyLimit('password_change')) return;
    if (!mounted) return;
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final primary = Theme.of(context).primaryColor;
    InputDecoration dialogFieldDecoration(String label) => InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primary, width: 2)),
        );
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('パスワード変更'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: newCtrl,
                      obscureText: true,
                      decoration: dialogFieldDecoration('新しいパスワード（10文字以上）'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      decoration: dialogFieldDecoration('パスワード（確認）'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!,
                          style: const TextStyle(
                              color: AppColors.errorColor, fontSize: 13)),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('キャンセル')),
                  ElevatedButton(
                    onPressed: () {
                      if (newCtrl.text.length < 10) {
                        setS(() => error = 'パスワードは10文字以上で入力してください');
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        setS(() => error = 'パスワードが一致しません');
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('変更'),
                  ),
                ],
              )),
    );
    final newPass = newCtrl.text;
    newCtrl.dispose();
    confirmCtrl.dispose();
    if (confirmed != true) return;
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPass));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('パスワードを変更しました'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('変更に失敗しました: $e'),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  bool _isDeletingAccount = false;

  Future<void> _deleteAccount() async {
    final confirmCtrl = TextEditingController();
    const confirmWord = '削除';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('アカウント削除', style: TextStyle(color: AppColors.errorColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'アカウントを削除すると、登録したお菓子の記録・お気に入り・プロフィール情報がすべて削除されます。この操作は取り消せません。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ログイン情報（メールアドレスとパスワード）自体の削除には運営側の対応が必要なため、完了までに数日いただきます。その間に同じメールアドレス・パスワードで再ログインすると、データが無い状態で利用が再開されますが、その後運営側が削除を完了すると、その間に新しく作成したデータも一緒に削除されますのでご注意ください。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 16),
                Text('確認のため「$confirmWord」と入力してください',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.blackLight)),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmCtrl,
                  onChanged: (_) => setS(() {}),
                  decoration: InputDecoration(
                    hintText: confirmWord,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: confirmCtrl.text == confirmWord
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.errorColor.withValues(alpha: 0.3),
              ),
              child: const Text('完全に削除する'),
            ),
          ],
        ),
      ),
    );
    confirmCtrl.dispose();
    if (confirmed != true) return;

    setState(() => _isDeletingAccount = true);
    try {
      final uid = _userId;
      if (uid != null) {
        // ログイン情報(auth.users)自体の削除にはサービスロールが必要なため
        // クライアントからは行えない。先に依頼をinquiryとして記録しておく
        // （これが無いと、データを消した後は運営側が削除依頼の存在に気づく手段が無くなる）。
        await supabase.from('inquiry').insert({
          'inquiry_type': 'account_deletion',
          'inquiry_email': _email,
          'inquiry_content': 'アカウント削除リクエスト（user_id: $uid）。データはアプリ側で削除済みのため、認証情報(auth.users)の削除をお願いします。',
          'user_id': uid,
        });
        // FKの参照方向に沿って、参照している側から先に削除する。
        await supabase.from('event').delete().eq('user_id', uid);
        await supabase.from('useritem').delete().eq('user_id', uid);
        await supabase.from('who').delete().eq('user_id', uid);
        await supabase.from('favorite').delete().eq('user_id', uid);
        await supabase.from('user').delete().eq('user_id', uid);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('data_migrated_$uid');
        await prefs.remove('migrated_present_ids_$uid');
        await prefs.remove('favorites_migrated_$uid');
        await prefs.remove('presents_cache_$uid');
        await prefs.remove('user_profile_icon_$uid');
        await prefs.remove(Constants.pendingSyncPresentsKey);
      }
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アカウントを削除しました。ご利用ありがとうございました。')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('削除に失敗しました: $e'),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  Future<void> _pickBirthday() async {
    final primary = Theme.of(context).primaryColor;
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: ColorScheme.light(primary: primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text('マイページ', style: TextStyle(color: primary)),
        iconTheme: IconThemeData(color: primary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Icon
                  GestureDetector(
                    onTap: () async {
                      final result = await showDialog<int>(
                        context: context,
                        builder: (_) => PersonIconPickerDialog(
                          personName: _nameCtrl.text.isNotEmpty
                              ? _nameCtrl.text
                              : 'ユーザー',
                          currentIndex: _iconIndex,
                        ),
                      );
                      if (result != null && _userId != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(
                            'user_profile_icon_$_userId', result);
                        setState(() => _iconIndex = result);
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _iconIndex != null &&
                                _iconIndex! >= 0 &&
                                _iconIndex! < kPersonIcons.length
                            ? CircleAvatar(
                                radius: 36,
                                backgroundColor:
                                    kPersonIcons[_iconIndex!].bgColor,
                                child: Text(kPersonIcons[_iconIndex!].emoji,
                                    style: const TextStyle(fontSize: 30)),
                              )
                            : CircleAvatar(
                                radius: 36,
                                backgroundColor:
                                    primary.withValues(alpha: 0.15),
                                child: Text(
                                  _nameCtrl.text.isNotEmpty
                                      ? _nameCtrl.text[0]
                                      : '?',
                                  style: TextStyle(
                                      fontSize: 28,
                                      color: primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                        Positioned(
                          bottom: -2,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color:
                                    AppColors.blackDark.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('変更',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Username
                  _buildSection(
                    title: 'ユーザー名',
                    child: TextField(
                      controller: _nameCtrl,
                      maxLength: 30,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: InputDecoration(
                        hintText: 'ユーザー名',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primary, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Email
                  _buildSection(
                    title: 'メールアドレス',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_email ?? '',
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.blackDark)),
                          trailing: TextButton(
                              onPressed: _changeEmail,
                              child:
                                  Text('変更', style: TextStyle(color: primary))),
                        ),
                        const Text('1日3回まで変更可能です',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.blackLight)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password
                  _buildSection(
                    title: 'パスワード',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('••••••••••',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.blackLight)),
                          trailing: TextButton(
                              onPressed: _changePassword,
                              child:
                                  Text('変更', style: TextStyle(color: primary))),
                        ),
                        const Text('1日3回まで変更可能です',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.blackLight)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Birthday
                  _buildSection(
                    title: '生年月日',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _birthday != null
                            ? '${_birthday!.year}年${_birthday!.month}月${_birthday!.day}日'
                            : '未設定',
                        style: TextStyle(
                            fontSize: 14,
                            color: _birthday != null
                                ? AppColors.blackDark
                                : AppColors.blackLight),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_birthday != null)
                            IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 20, color: AppColors.blackLight),
                              tooltip: 'クリア',
                              onPressed: () => setState(() => _birthday = null),
                            ),
                          TextButton(
                              onPressed: _pickBirthday,
                              child:
                                  Text('設定', style: TextStyle(color: primary))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gender
                  _buildSection(
                    title: '性別',
                    child: Row(
                      children: ['女性', '男性', '無回答']
                          .map((g) => Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _gender = g),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<String>(
                                        value: g,
                                        groupValue: _gender,
                                        onChanged: (v) =>
                                            setState(() => _gender = v),
                                        activeColor: primary,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      Text(g,
                                          style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSaving || _loadFailed) ? null : _save,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('保存',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _isDeletingAccount ? null : _deleteAccount,
                      icon: _isDeletingAccount
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.errorColor))
                          : const Icon(Icons.delete_forever,
                              color: AppColors.errorColor, size: 18),
                      label: const Text('アカウントを削除する',
                          style: TextStyle(color: AppColors.errorColor)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.blackLight,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
