import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/view/present.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('データの読み込みに失敗しました: $e'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        radius: 20,
                        child: Text(
                          person.isNotEmpty ? person[0] : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.blackDark,
                          ),
                        ),
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
                                color: AppColors.blackLight.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'まだプレゼントの記録がありません',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.blackLight.withOpacity(0.7),
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
                                          : const Icon(
                                              Icons.image_outlined,
                                              size: 32,
                                              color: AppColors.blackLight,
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
                                                  color: AppColors.blackLight,
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
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
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
                    image: AssetImage('lib/widgets/lace.png'),
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
                _buildSettingsSection(),
              ],
            ),
          ),
        ),
      ),
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
              color: AppColors.primaryColor.withOpacity(0.1),
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
                    color: AppColors.primaryColor,
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
                        'プレゼントした人一覧',
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
              ? const SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
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
                              color: AppColors.blackLight.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'まだプレゼントした人がいません',
                              style: TextStyle(
                                color: AppColors.blackLight.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'プレゼントを記録すると、ここに表示されます',
                              style: TextStyle(
                                color: AppColors.blackLight.withOpacity(0.5),
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
                                    CircleAvatar(
                                      backgroundColor: AppColors.primaryColor,
                                      radius: 22,
                                      child: Text(
                                        person.isNotEmpty ? person[0] : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.blackDark,
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

  Widget _buildSettingsSection() {
    final settingsItems = [
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
    ];

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
                          color: AppColors.primaryColor.withOpacity(0.1),
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
    Widget screen;

    switch (title) {
      case 'アプリについて':
        screen = _buildAboutScreen();
        break;
      case 'お問い合わせ':
        screen = _buildContactScreen();
        break;
      case '運営会社・利用規約':
        screen = _buildTermsScreen();
        break;
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
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
        const Text(
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
        _buildFeatureItem(Icons.search, '商品検索',
            'おすすめ商品を編集部が随時更新しています。お気に入りをして贈り物やご褒美の参考にしよう'),
        _buildFeatureItem(
            Icons.star_outline, '反応や評価を記録', '贈った時の反応や自己評価を5段階で記録できます'),
        _buildFeatureItem(
            Icons.people_outline, '人別管理', '贈った人ごとに履歴を管理できます。次の贈り物の機会に読み返そう'),
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
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
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
                        color: AppColors.primaryColor.withOpacity(0.1),
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
        color: AppColors.greyLight.withOpacity(0.5),
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
                    const BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
            items: const [
              DropdownMenuItem(value: 'お菓子名', child: Text('お菓子名')),
              DropdownMenuItem(value: '会社名', child: Text('会社名')),
              DropdownMenuItem(value: '画像', child: Text('画像')),
              DropdownMenuItem(value: 'ジャンル', child: Text('ジャンル')),
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
          const Text(
            '正しい内容 *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.blackLight,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.correctContentController,
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
                borderSide: const BorderSide(
                    color: AppColors.inputFocusColor, width: 2),
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
              hintText: '正しい内容を入力してください',
            ),
            maxLines: 3,
            minLines: 2,
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
        return sweetData['item_company'] ?? '不明';
      case 'ジャンル':
        return sweetData['item_genre'] ?? '不明';
      case '金額':
        return '¥${Utils.formatCurrency(sweetData['item_price'])}';
      case '賞味期限':
        return sweetData['item_expiry'] ?? '不明';
      case '個包装':
        return sweetData['item_individual_packaging'] == 1 ? 'あり' : 'なし';
      case '常温':
        return sweetData['item_room_temperature'] == 1 ? '常温保存可能' : '要冷蔵・冷凍';
      case 'オンライン購入':
        return sweetData['item_online_purchase'] == 1 ? '購入可能' : '購入不可';
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
        const Text(
          '不具合の内容 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bugReportController,
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
            hintText: '不具合の詳細を入力してください',
          ),
          maxLines: 5,
          minLines: 3,
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
        const Text(
          'お名前 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otherNameController,
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
            hintText: 'お名前を入力してください',
          ),
        ),
        const SizedBox(height: 16),
        // メールアドレス
        const Text(
          'メールアドレス *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otherEmailController,
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
            hintText: 'メールアドレスを入力してください',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const Text(
          'お問い合わせ内容 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otherInquiryController,
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
            hintText: 'お問い合わせ内容を入力してください',
          ),
          maxLines: 5,
          minLines: 3,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greyLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyMedium),
          ),
          child: const Text(
            '本アプリは2025年現在、個人が運営しております。お問い合わせに対する返信は必ず行われるものではございませんので、ご了承ください。',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.blackLight,
              height: 1.5,
            ),
          ),
        ),
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
        // 会社名
        const Text(
          '会社名 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessCompanyController,
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
            hintText: '会社名を入力してください',
          ),
        ),
        const SizedBox(height: 16),
        // ご担当者名
        const Text(
          'ご担当者名 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessNameController,
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
            hintText: 'ご担当者名を入力してください',
          ),
        ),
        const SizedBox(height: 16),
        // メールアドレス
        const Text(
          'メールアドレス *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessEmailController,
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
            hintText: 'メールアドレスを入力してください',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const Text(
          'お問い合わせ内容 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessController,
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
            hintText: '企業様からの商品情報提供や宣伝のご活用お待ちしております。内容を入力してください',
          ),
          maxLines: 5,
          minLines: 3,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greyLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyMedium),
          ),
          child: const Text(
            '本アプリは2025年現在、個人が運営しております。お問い合わせに対する返信は必ず行われるものではございませんので、ご了承ください。',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.blackLight,
              height: 1.5,
            ),
          ),
        ),
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
          backgroundColor: AppColors.primaryColor,
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
      await _sendEmail(
        subject: '【アプリ】情報の間違い報告',
        body: _buildErrorReportEmailBody(),
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
      await _sendEmail(
        subject: '【アプリ】不具合報告',
        body: '不具合の内容：\n${_bugReportController.text}',
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
      await _sendEmail(
        subject: '【アプリ】その他問い合わせ',
        body:
            'お名前：${_otherNameController.text}\nメールアドレス：${_otherEmailController.text}\nお問い合わせ内容：\n${_otherInquiryController.text}',
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
      await _sendEmail(
        subject: '【アプリ】企業様からのお問い合わせ',
        body:
            '会社名：${_businessCompanyController.text}\nご担当者名：${_businessNameController.text}\nメールアドレス：${_businessEmailController.text}\nお問い合わせ内容：\n${_businessController.text}',
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
                  backgroundColor: AppColors.primaryColor,
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

  Future<void> _sendEmail(
      {required String subject, required String body}) async {
    try {
      // 開発用：コンソールに出力（実際の実装では削除）
      print('=== メール送信 ===');
      print('宛先: ---@gmail.com');
      print('件名: $subject');
      print('本文: $body');
      print('================');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('送信完了しました'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _clearForm();
      setState(() => _expandedSection = -1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('送信に失敗しました: $e'),
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
  }
}

Widget _buildTermsScreen() {
  return Scaffold(
    backgroundColor: AppColors.greyLight,
    appBar: AppBar(
      title: const Text(
        '運営会社・利用規約',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.primaryColor),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 運営者情報セクション
          Container(
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '運営者情報',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('事業者名', '合同会社カイエ Cahier'),
                  _buildInfoRow('事業内容', 'モバイルアプリケーションの企画・開発・運営'),
                  _buildInfoRow('連絡先', 'メールアドレス：aaa@gmail.com'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 利用規約セクション
          Container(
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '利用規約',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.update,
                          color: AppColors.blackDark,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '最終更新日：[更新日]',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blackDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'この利用規約（以下「本規約」）は、合同会社カイエ（以下「当方」）が提供するモバイルアプリケーション「ア・ラ・モード」（以下「本サービス」）の利用条件を定めるものです。本サービスをご利用になる場合には、本規約に同意いただいたものとみなします。',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.blackLight,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTermsSection(
                      '第1条（適用）',
                      '1. 本規約は、ユーザーと当方との間の本サービスの利用に関わる一切の関係に適用されるものとします。\n'
                          '2. 当方は本サービスに関し、本規約のほか、ご利用にあたってのルール等、各種の定め（以下「個別規定」）をすることがあります。これら個別規定はその名称のいかんに関わらず、本規約の一部を構成するものとします。\n'
                          '3. 本規約の規定が前項の個別規定の規定と矛盾する場合には、個別規定において特段の定めなき限り、個別規定の規定が優先されるものとします。'),
                  _buildTermsSection(
                      '第2条（利用登録）',
                      '1. 本サービスにおいては、登録希望者が本規約に同意の上、当方の定める方法によって利用登録を申請し、当方がこれを承認することによって、利用登録が完了するものとします。\n'
                          '2. 当方は、利用登録の申請者に以下の事由があると判断した場合、利用登録の申請を承認しないことがあり、その理由については一切の開示義務を負わないものとします。\n'
                          '・利用登録の申請に際して虚偽の事項を届け出た場合\n'
                          '・本規約に違反したことがある者からの申請である場合\n'
                          '・その他、当社が利用登録を相当でないと判断した場合'),
                  _buildTermsSection(
                      '第3条（アカウント管理）',
                      '1. ユーザーは、自己の責任において、本サービスのアカウント情報を適切に管理するものとします。\n'
                          '2. ユーザーは、いかなる場合にも、アカウント情報を第三者に譲渡または貸与し、もしくは第三者と共用することはできません。\n'
                          '3. アカウント情報の管理不十分、使用上の過誤、第三者の使用等によって生じた損害の責任は、ユーザーが負うものとします。'),
                  _buildTermsSection(
                      '第4条（サービス内容）',
                      '1. 本サービスは無料でご利用いただけます。\n'
                          '2. 本サービスで登録されたデータは、主にオフラインでの利用を想定しています。'),
                  _buildTermsSection(
                      '第5条（個人情報の取扱い）',
                      '1. 当方は、本サービスの利用によって取得する個人情報については、当方プライバシーポリシーに従い適切に取り扱います。\n'
                          '2. 当方は、個人を特定できない形で統計的に処理したデータについて、サービス改善やその他の目的で利用する場合があります。'),
                  _buildTermsSection(
                      '第6条（禁止事項）',
                      'ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。\n'
                          '1. 法令または公序良俗に違反する行為\n'
                          '2. 犯罪行為に関連する行為\n'
                          '3. 当社、本サービスの他のユーザー、または第三者のサーバーまたはネットワークの機能を破壊したり、妨害したりする行為'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '以上',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.blackLight,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFeatureItem(IconData icon, String title, String description) {
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
            color: AppColors.primaryColor,
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

Widget _buildInfoRow(String label, String content) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.blackDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.blackDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTermsSection(String title, String content) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.blackDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.greyMedium,
              width: 1,
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.blackLight,
              height: 1.6,
            ),
          ),
        ),
      ],
    ),
  );
}
