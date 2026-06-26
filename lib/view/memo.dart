import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/widgets/category_placeholder.dart';
import 'package:alamode_app/widgets/person_icon.dart';
import 'package:alamode_app/services/auth_service.dart';
import 'package:alamode_app/view/auth.dart';

final presentLogger = Logger('PresentManagement');

class Constants {
  static const String presentListKey = 'present_list';
  static const int maxImageSize = 1024 * 1024; // 1MB
  static const int targetImageWidth = 1024;
  static const int memoMaxLength = 200;
  static const double maxPriceFilter = 20000;
}

class Utils {
  static String formatCurrency(dynamic value) {
    if (value == null) return '';
    return NumberFormat('#,###').format(value);
  }

  static String normalizeString(String input) {
    String katakana = input.replaceAllMapped(RegExp(r'[ぁ-ん]'),
        (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 0x60));

    return katakana.toLowerCase().replaceAll(RegExp(r'[、。，．・：；？！～ー\s]'), '');
  }

  static String generateUniqueId() {
    final now = DateTime.now();
    final datePart = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final randomPart = _generateRandomString(6);
    return '$datePart$randomPart';
  }

  static String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class CommonWidgets {
  static Widget buildReactionStar(int presentReaction,
      {double size = 40, Function(int)? onTap}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: onTap != null ? 8.0 : 0),
          child: GestureDetector(
            onTap: onTap != null ? () => onTap(starNumber) : null,
            child: Icon(
              Icons.star,
              color: presentReaction >= starNumber
                  ? AppColors.starColor
                  : AppColors.greyMedium,
              size: size,
            ),
          ),
        );
      }),
    );
  }

  static Widget buildGenreSelector({
    required BuildContext context,
    required Set<String> selectedGenres,
    required Function(Set<String>) onSelectionChanged,
    bool multiSelect = false,
  }) {
    const genres = ['クッキー', 'ショコラ', '和菓子', '焼き菓子', 'ゼリー・プリン', 'その他'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ジャンル',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: genres.map((genre) {
            final isSelected = selectedGenres.contains(genre);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Set<String> newSelection = Set.from(selectedGenres);
                  if (isSelected) {
                    newSelection.remove(genre);
                  } else {
                    if (!multiSelect) {
                      newSelection.clear(); // 単一選択の場合
                    }
                    newSelection.add(genre);
                  }
                  onSelectionChanged(newSelection);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : AppColors.greyLight,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : AppColors.blackLight,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget buildOtherConditionSelector({
    required BuildContext context,
    required Set<String> selectedConditions,
    required Function(Set<String>) onSelectionChanged,
    bool multiSelect = false,
  }) {
    const conditions = ['個包装', '常温', 'オンライン購入'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'その他',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: conditions.map((condition) {
            final isSelected = selectedConditions.contains(condition);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Set<String> newSelection = Set.from(selectedConditions);
                  if (isSelected) {
                    newSelection.remove(condition);
                  } else {
                    if (!multiSelect) {
                      newSelection.clear(); // 単一選択の場合
                    }
                    newSelection.add(condition);
                  }
                  onSelectionChanged(newSelection);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : AppColors.greyDark,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        condition,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.blackDark
                              : AppColors.blackLight,
                          fontWeight: FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Text(
                          '○',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget buildInfoRow(IconData icon, String? text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blackDark, size: 16),
        const SizedBox(width: 4),
        Text(text ?? '',
            style: const TextStyle(color: AppColors.blackDark, fontSize: 14)),
      ],
    );
  }

  static Widget buildImage(String? imageUrl, PresentManagementService service) {
    if (imageUrl == null) {
      return Container(
        color: AppColors.greyLight,
        child: const Icon(Icons.image, color: AppColors.greyLight),
      );
    }

    return FutureBuilder<String?>(
      future: service.getImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Container(
            color: AppColors.warmWhite,
            child: kIsWeb
                ? Image.memory(base64Decode(snapshot.data!), fit: BoxFit.contain)
                : Image.file(File(snapshot.data!), fit: BoxFit.contain),
          );
        }
        return Container(
          color: AppColors.greyLight,
          child: const Icon(Icons.image, color: AppColors.greyLight),
        );
      },
    );
  }

  static InputDecoration buildInputDecoration(String labelText,
      {Widget? suffixIcon, BuildContext? context}) {
    final focusColor = context != null
        ? Theme.of(context).primaryColor
        : AppColors.inputFocusColor;
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: AppColors.blackLight,
      ),
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
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      filled: true,
      fillColor: AppColors.cardBackground,
      suffixIcon: suffixIcon,
    );
  }
}

enum SortOrder {
  registrationOrderNew,
  dateNew,
  dateOld,
  reactionHigh,
  priceLow,
  priceHigh,
  brand
}

enum SearchType { name, brand }

class PresentManagementService {
  Future<String?> saveImageLocally(XFile pickedFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await pickedFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('画像のデコードに失敗しました');
      final imageData =
          bytes.length > Constants.maxImageSize ? _compressImage(image) : bytes;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('image_$fileName', base64Encode(imageData));
        return 'image_$fileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(imageData);
        return file.path;
      }
    } catch (e) {
      presentLogger.warning('画像の保存に失敗しました: $e');
      return null;
    }
  }

  Uint8List _compressImage(img.Image image) {
    final targetHeight =
        (image.height * Constants.targetImageWidth / image.width).round();
    final resizedImage = img.copyResize(image,
        width: Constants.targetImageWidth, height: targetHeight);
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }

  Future<String?> getImage(String key) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } else {
        return await File(key).exists() ? key : null;
      }
    } catch (e) {
      presentLogger.warning('画像の読み込みに失敗しました: $e');
      return null;
    }
  }

  Future<void> savePresent(Map<String, dynamic> presentData) async {
    if (AuthService.instance.isLoggedIn) {
      await _savePresentToSupabase(presentData);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final presentList = prefs.getStringList(Constants.presentListKey) ?? [];
      presentData['present_id'] ??= Utils.generateUniqueId();
      presentData['present_createdate'] ??= DateTime.now().toIso8601String();
      presentList.add(jsonEncode(presentData));
      await prefs.setStringList(Constants.presentListKey, presentList);
    } catch (e) {
      throw Exception('保存に失敗しました: $e');
    }
  }

  Future<void> updatePresent(Map<String, dynamic> presentData) async {
    if (AuthService.instance.isLoggedIn) {
      await _updatePresentInSupabase(presentData);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final presentList = prefs.getStringList(Constants.presentListKey) ?? [];
      final presentId = presentData['present_id'];

      final index = presentList.indexWhere((item) {
        final data = jsonDecode(item) as Map<String, dynamic>;
        return data['present_id'] == presentId;
      });

      if (index != -1) {
        presentList[index] = jsonEncode(presentData);
        await prefs.setStringList(Constants.presentListKey, presentList);
      }
    } catch (e) {
      presentLogger.warning('更新に失敗しました: $e');
      rethrow;
    }
  }

  Future<void> deletePresent(String presentId) async {
    if (AuthService.instance.isLoggedIn) {
      await _deletePresentFromSupabase(presentId);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final presentList = prefs.getStringList(Constants.presentListKey) ?? [];

      presentList.removeWhere((item) {
        final data = jsonDecode(item) as Map<String, dynamic>;
        return data['present_id'] == presentId;
      });

      await prefs.setStringList(Constants.presentListKey, presentList);
    } catch (e) {
      presentLogger.warning('削除に失敗しました: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllPresents() async {
    if (AuthService.instance.isLoggedIn) {
      return _getAllPresentsFromSupabase();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final presentList = prefs.getStringList(Constants.presentListKey) ?? [];
      return presentList
          .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
          .toList();
    } catch (e) {
      presentLogger.warning('データの読み込みに失敗しました: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAllPresentsFromSupabase() async {
    final uid = AuthService.instance.userId!;
    try {
      final data = await supabase
          .from('event')
          .select('event_id, event_how, event_reaction_rating, event_date, event_memo, event_createdate, useritem(useritem_id, useritem_name, useritem_brand, useritem_category, useritem_price, useritem_roomtemperature, useritem_individualwrapping, useritem_online, useritem_memo, useritem_image), who(who_id, who_name)')
          .eq('user_id', uid)
          .order('event_createdate', ascending: false);
      return (data as List).map((e) => _supabaseToPresent(e as Map<String, dynamic>)).toList();
    } catch (e) {
      presentLogger.warning('Supabaseからの読み込みに失敗: $e');
      return [];
    }
  }

  static Map<String, dynamic> _supabaseToPresent(Map<String, dynamic> event) {
    final useritem = event['useritem'] as Map<String, dynamic>? ?? {};
    final who = event['who'] as Map<String, dynamic>?;
    final conditions = <String>[];
    if (useritem['useritem_roomtemperature'] == 'yes') conditions.add('常温');
    if (useritem['useritem_individualwrapping'] == 'yes') conditions.add('個包装');
    if (useritem['useritem_online'] == 'yes') conditions.add('オンライン購入');
    return {
      'present_id': event['event_id'],
      'present_type': event['event_how'] == 'treat' ? 'received' : 'sent',
      'present_name': useritem['useritem_name'] ?? '',
      'present_brand': useritem['useritem_brand'] ?? '',
      'present_genre': useritem['useritem_category'] ?? '',
      'present_price': useritem['useritem_price'] ?? 0,
      'present_date': event['event_date'] ?? '',
      'present_who': who?['who_name'] ?? '',
      'present_reaction': event['event_reaction_rating'] ?? 0,
      'present_other_conditions': conditions.join(', '),
      'present_memo': useritem['useritem_memo'] ?? '',
      'present_imageurl': useritem['useritem_image'],
      'present_imageurl2': null,
      'present_imageurl3': null,
      'present_createdate': event['event_createdate'] ?? DateTime.now().toIso8601String(),
      '_event_id': event['event_id'],
      '_useritem_id': useritem['useritem_id'],
      '_who_id': who?['who_id'],
    };
  }

  Future<void> _savePresentToSupabase(Map<String, dynamic> data) async {
    final uid = AuthService.instance.userId!;
    final whoName = data['present_who'] as String? ?? '';
    String? whoId;
    if (whoName.isNotEmpty) {
      whoId = await AuthService.instance.getOrCreateWho(uid, whoName);
    }
    final otherConditions = data['present_other_conditions'] as String? ?? '';
    final useritemResult = await supabase.from('useritem').insert({
      'user_id': uid,
      'useritem_name': data['present_name'] ?? '',
      'useritem_brand': data['present_brand'] ?? '',
      'useritem_category': data['present_genre'] ?? '',
      'useritem_price': data['present_price'] ?? 0,
      'useritem_roomtemperature': otherConditions.contains('常温') ? 'yes' : 'no',
      'useritem_individualwrapping': otherConditions.contains('個包装') ? 'yes' : 'no',
      'useritem_online': otherConditions.contains('オンライン購入') ? 'yes' : 'no',
      'useritem_memo': data['present_memo'] ?? '',
      'useritem_URL': '',
      'useritem_image': data['present_imageurl'],
      'useritem_createdate': DateTime.now().toIso8601String(),
      'useritem_update': DateTime.now().toIso8601String(),
    }).select('useritem_id').single();
    await supabase.from('event').insert({
      'user_id': uid,
      'useritem_id': useritemResult['useritem_id'],
      'event_how': data['present_type'] == 'received' ? 'treat' : 'present',
      'event_reaction_rating': data['present_reaction'] ?? 0,
      'event_taste_rating': 0,
      'event_memo': data['present_memo'] ?? '',
      'who_id': whoId,
      'event_date': data['present_date'],
      'event_createdate': DateTime.now().toIso8601String(),
      'event_update': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updatePresentInSupabase(Map<String, dynamic> data) async {
    final uid = AuthService.instance.userId!;
    final eventId = data['_event_id'] ?? data['present_id'];
    final useritemId = data['_useritem_id'];
    if (eventId == null || useritemId == null) return;
    final whoName = data['present_who'] as String? ?? '';
    String? whoId;
    if (whoName.isNotEmpty) {
      whoId = await AuthService.instance.getOrCreateWho(uid, whoName);
    }
    final otherConditions = data['present_other_conditions'] as String? ?? '';
    await supabase.from('useritem').update({
      'useritem_name': data['present_name'] ?? '',
      'useritem_brand': data['present_brand'] ?? '',
      'useritem_category': data['present_genre'] ?? '',
      'useritem_price': data['present_price'] ?? 0,
      'useritem_roomtemperature': otherConditions.contains('常温') ? 'yes' : 'no',
      'useritem_individualwrapping': otherConditions.contains('個包装') ? 'yes' : 'no',
      'useritem_online': otherConditions.contains('オンライン購入') ? 'yes' : 'no',
      'useritem_memo': data['present_memo'] ?? '',
      'useritem_image': data['present_imageurl'],
      'useritem_update': DateTime.now().toIso8601String(),
    }).eq('useritem_id', useritemId);
    await supabase.from('event').update({
      'event_how': data['present_type'] == 'received' ? 'treat' : 'present',
      'event_reaction_rating': data['present_reaction'] ?? 0,
      'event_memo': data['present_memo'] ?? '',
      'who_id': whoId,
      'event_date': data['present_date'],
      'event_update': DateTime.now().toIso8601String(),
    }).eq('event_id', eventId);
  }

  Future<void> _deletePresentFromSupabase(String presentId) async {
    final eventData = await supabase
        .from('event')
        .select('useritem_id')
        .eq('event_id', presentId)
        .maybeSingle();
    await supabase.from('event').delete().eq('event_id', presentId);
    if (eventData != null) {
      final useritemId = eventData['useritem_id'];
      if (useritemId != null) {
        final others = await supabase.from('event').select('event_id').eq('useritem_id', useritemId);
        if ((others as List).isEmpty) {
          await supabase.from('useritem').delete().eq('useritem_id', useritemId);
        }
      }
    }
  }

  Future<List<String>> getWhoNamesFromSupabase() async {
    final uid = AuthService.instance.userId!;
    final data = await supabase
        .from('who')
        .select('who_name')
        .eq('user_id', uid)
        .order('who_name');
    return (data as List).map((e) => e['who_name'] as String).toList();
  }
}

class PresentList extends StatefulWidget {
  final PresentManagementService presentService;

  const PresentList({
    super.key,
    required this.presentService,
  });

  @override
  State<PresentList> createState() => _PresentListState();
}

class _PresentListState extends State<PresentList> {
  List<Map<String, dynamic>> _presentList = [];
  List<Map<String, dynamic>> _filteredList = [];
  SortOrder _currentSortOrder = SortOrder.registrationOrderNew;
  Map<String, bool> _filterWho = {};
  Map<String, bool> _filterReaction = {};
  Map<String, bool> _filterGenre = {};
  double _filterPriceMin = 0;
  double _filterPriceMax = Constants.maxPriceFilter;
  bool _isLoading = false;
  final currencyFormat = NumberFormat('#,###');
  Map<String, bool> _filterOtherCondition = {};
  bool _showSentPresents = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    await _loadTabState();
    await _loadPresentList();
    await _loadSortOrder();
    _checkLoginPrompt();
  }

  Future<void> _checkLoginPrompt() async {
    if (AuthService.instance.isLoggedIn) return;
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('login_popup_dismissed') ?? false;
    if (!dismissed && mounted) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const LoginPromptDialog(),
      );
      if (result == 'login' && mounted) {
        final loggedIn = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        if (loggedIn == true) await _loadPresentList();
      }
    }
  }

  Future<void> _loadTabState() async {
    final prefs = await SharedPreferences.getInstance();
    final showSent = prefs.getBool('memo_show_sent') ?? true;
    setState(() => _showSentPresents = showSent);
  }

  Future<void> _saveTabState(bool showSent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('memo_show_sent', showSent);
  }

  Future<void> _loadSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrderIndex = prefs.getInt('sortOrder');
    if (savedOrderIndex != null && savedOrderIndex < SortOrder.values.length) {
      setState(() {
        _currentSortOrder = SortOrder.values[savedOrderIndex];
      });
    }
  }

  Future<void> _loadPresentList() async {
    setState(() => _isLoading = true);
    try {
      _presentList = await widget.presentService.getAllPresents();
      _applyFiltersAndSort();
    } catch (e) {
      presentLogger.warning('読み込みに失敗しました: $e');
      Utils.showSnackBar(context, '読み込みに失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PresentFilterDialog(
        presentList: _presentList,
        currentFilterGenre: _filterGenre,
        currentFilterWho: _filterWho,
        currentFilterReaction: _filterReaction,
        currentFilterOtherCondition: _filterOtherCondition,
        currentPriceMin: _filterPriceMin,
        currentPriceMax: _filterPriceMax,
      ),
    );
    if (result != null) {
      setState(() {
        _filterGenre = result['filterGenre'];
        _filterWho = result['filterWho'];
        _filterReaction = result['filterReaction'];
        _filterOtherCondition = result['filterOtherCondition'];
        _filterPriceMin = result['filterPriceMin'];
        _filterPriceMax = result['filterPriceMax'];
      });
      _applyFiltersAndSort();
    }
  }

  Future<void> _saveSortOrder(SortOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortOrder', order.index);
  }

  void _applyFiltersAndSort() {
    _filteredList = _presentList.where(_meetsFilterCriteria).toList();
    _filteredList.sort(_comparePresents);
    setState(() {});
  }

  int _comparePresents(Map<String, dynamic> a, Map<String, dynamic> b) {
    switch (_currentSortOrder) {
      case SortOrder.registrationOrderNew:
        return (b['present_createdate'] ?? '')
            .compareTo(a['present_createdate'] ?? '');
      case SortOrder.dateNew:
        return (b['present_date'] ?? '').compareTo(a['present_date'] ?? '');
      case SortOrder.dateOld:
        return (a['present_date'] ?? '').compareTo(b['present_date'] ?? '');
      case SortOrder.reactionHigh:
        return (b['present_reaction'] ?? 0)
            .compareTo(a['present_reaction'] ?? 0);
      case SortOrder.priceLow:
        return (a['present_price'] ?? 0).compareTo(b['present_price'] ?? 0);
      case SortOrder.priceHigh:
        return (b['present_price'] ?? 0).compareTo(a['present_price'] ?? 0);
      case SortOrder.brand:
        return (a['present_brand'] ?? '').compareTo(b['present_brand'] ?? '');
      default:
        return 0;
    }
  }

  bool _meetsFilterCriteria(Map<String, dynamic> present) {
    // 送った/貰ったフィルタリング
    final presentType = present['present_type'] ?? 'sent';
    if (_showSentPresents && presentType != 'sent') return false;
    if (!_showSentPresents && presentType != 'received') return false;

    // ジャンルフィルタリング
    if (_filterGenre.isNotEmpty &&
        !(_filterGenre[present['present_genre']] ?? false)) {
      return false;
    }

    // 相手フィルタリング
    if (_filterWho.isNotEmpty &&
        !(_filterWho[present['present_who']] ?? false)) {
      return false;
    }

    // 反応フィルタリング
    if (_filterReaction.isNotEmpty &&
        !(_filterReaction[present['present_reaction'].toString()] ?? false)) {
      return false;
    }

// その他条件フィルタリング
    if (_filterOtherCondition.isNotEmpty) {
      String presentOtherConditions = present['present_other_conditions'] ?? '';
      bool matchesOtherCondition = false;
      _filterOtherCondition.forEach((condition, isSelected) {
        if (isSelected && presentOtherConditions.contains(condition)) {
          matchesOtherCondition = true;
        }
      });
      if (!matchesOtherCondition) {
        return false;
      }
    }

    // 価格フィルタリング
    final presentPrice = present['present_price'] as int?;
    if (presentPrice == null ||
        presentPrice < _filterPriceMin ||
        (_filterPriceMax < Constants.maxPriceFilter &&
            presentPrice > _filterPriceMax)) {
      return false;
    }
    return true;
  }

  Widget _buildTypeToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            label: '贈った',
            icon: Icons.card_giftcard,
            isSelected: _showSentPresents,
            onTap: () {
              if (!_showSentPresents) {
                setState(() => _showSentPresents = true);
                _saveTabState(true);
                _applyFiltersAndSort();
              }
            },
          ),
          _buildToggleOption(
            label: '貰った',
            icon: Icons.restaurant,
            isSelected: !_showSentPresents,
            onTap: () {
              if (_showSentPresents) {
                setState(() => _showSentPresents = false);
                _saveTabState(false);
                _applyFiltersAndSort();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Theme.of(context).primaryColor : AppColors.blackLight,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : AppColors.blackLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterAndSortRow() {
    if (_presentList.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // アクティブフィルターの横スクロール表示
          if (_hasActiveFilters())
            Expanded(child: _buildActiveFilters())
          else
            const Expanded(child: SizedBox()),
          // フィルター・ソートボタン行
          IconButton(
            icon: const Icon(
              Icons.filter_list_alt,
              color: AppColors.blackLight,
            ),
            tooltip: 'フィルタリング',
            onPressed: _openFilterDialog,
          ),
          PopupMenuButton<SortOrder>(
            icon: const Icon(
              Icons.sort,
              color: AppColors.blackLight,
            ),
            tooltip: '並び替え',
            onSelected: (value) async {
              setState(() => _currentSortOrder = value);
              await _saveSortOrder(value);
              _applyFiltersAndSort();
            },
            itemBuilder: (context) => [
              _buildSortMenuItem(SortOrder.registrationOrderNew, '登録日が新しい順'),
              _buildSortMenuItem(SortOrder.dateNew, '日付が新しい順'),
              _buildSortMenuItem(SortOrder.dateOld, '日付が古い順'),
              _buildSortMenuItem(SortOrder.reactionHigh, '反応が高い順'),
              _buildSortMenuItem(SortOrder.priceLow, '価格の安い順'),
              _buildSortMenuItem(SortOrder.priceHigh, '価格の高い順'),
              _buildSortMenuItem(SortOrder.brand, 'ブランド名順'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortOrder> _buildSortMenuItem(SortOrder value, String label) {
    return PopupMenuItem<SortOrder>(
      value: value,
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: _currentSortOrder == value
                ? Theme.of(context).primaryColor
                : Colors.transparent,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    final hasGenreFilter = _filterGenre.values.any((selected) => selected);
    final hasWhoFilter = _filterWho.values.any((selected) => selected);
    final hasReactionFilter =
        _filterReaction.values.any((selected) => selected);
    final hasOtherConditionFilter =
        _filterOtherCondition.values.any((selected) => selected);
    final hasPriceFilter =
        _filterPriceMin > 0 || _filterPriceMax < Constants.maxPriceFilter;
    return hasGenreFilter ||
        hasWhoFilter ||
        hasReactionFilter ||
        hasOtherConditionFilter ||
        hasPriceFilter;
  }

  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    // ジャンルフィルター
    _filterGenre.forEach((genre, isSelected) {
      if (isSelected) {
        filterChips.add(_buildFilterChip(
          label: genre,
          onRemove: () {
            setState(() {
              _filterGenre[genre] = false;
            });
            _applyFiltersAndSort();
          },
        ));
      }
    });

    // 相手フィルター
    _filterWho.forEach((who, isSelected) {
      if (isSelected) {
        filterChips.add(_buildFilterChip(
          label: who,
          onRemove: () {
            setState(() {
              _filterWho[who] = false;
            });
            _applyFiltersAndSort();
          },
        ));
      }
    });

    // 反応フィルター
    _filterReaction.forEach((reaction, isSelected) {
      if (isSelected) {
        filterChips.add(_buildFilterChip(
          label: '★$reaction',
          onRemove: () {
            setState(() {
              _filterReaction[reaction] = false;
            });
            _applyFiltersAndSort();
          },
        ));
      }
    });

// その他条件フィルター
    _filterOtherCondition.forEach((condition, isSelected) {
      if (isSelected) {
        filterChips.add(_buildFilterChip(
          label: condition,
          onRemove: () {
            setState(() {
              _filterOtherCondition[condition] = false;
            });
            _applyFiltersAndSort();
          },
        ));
      }
    });

    // 価格フィルター
    if (_filterPriceMin > 0 || _filterPriceMax < Constants.maxPriceFilter) {
      String priceLabel = '';
      if (_filterPriceMin > 0 && _filterPriceMax < Constants.maxPriceFilter) {
        priceLabel =
            '¥${NumberFormat('#,###').format(_filterPriceMin.toInt())} - ¥${NumberFormat('#,###').format(_filterPriceMax.toInt())}';
      } else if (_filterPriceMin > 0) {
        priceLabel =
            '¥${NumberFormat('#,###').format(_filterPriceMin.toInt())}以上';
      } else {
        priceLabel =
            '¥${NumberFormat('#,###').format(_filterPriceMax.toInt())}以下';
      }

      filterChips.add(_buildFilterChip(
        label: priceLabel,
        onRemove: () {
          setState(() {
            _filterPriceMin = 0;
            _filterPriceMax = Constants.maxPriceFilter;
          });
          _applyFiltersAndSort();
        },
      ));
    }

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...filterChips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: chip,
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label, required VoidCallback onRemove}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.blackDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(left: 4, right: 4),
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.blackLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentItem(Map<String, dynamic> present) {
    return GestureDetector(
      onTap: () => _navigateToEdit(present),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPresentHeader(present),
            _buildPresentImages(present['present_imageurl'], present['present_genre']),
            _buildPresentFooter(present),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentImages(String? imageUrl, String? genre) {
    if (imageUrl != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: CommonWidgets.buildImage(imageUrl, widget.presentService),
          ),
        ),
      );
    }
    if (genre == null || genre.isEmpty) {
      return CategoryPlaceholder(category: null, height: 100);
    }
    final categories = genre.split(', ').where((s) => s.isNotEmpty).take(3).toList();
    if (categories.length == 1) {
      return CategoryPlaceholder(category: categories[0], height: 100);
    }
    return SizedBox(
      height: 100,
      child: Row(
        children: categories.map((cat) => Expanded(
          child: CategoryPlaceholder(category: cat, height: 100),
        )).toList(),
      ),
    );
  }

  Widget _buildPresentHeader(Map<String, dynamic> present) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: name + date
          Row(
            children: [
              Expanded(
                child: Text(
                  present['present_name'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.calendar_month, size: 13, color: AppColors.blackLight),
              const SizedBox(width: 3),
              Text(
                present['present_date'] ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.blackLight),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Row 2: brand + genre badge flush right
          Row(
            children: [
              const Icon(Icons.storefront, size: 13, color: AppColors.blackLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  present['present_brand'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.blackLight),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (present['present_genre'] != null &&
                  present['present_genre'].toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyDark, width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    present['present_genre'],
                    style: const TextStyle(fontSize: 10, color: AppColors.blackLight),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          // Row 3: person avatar + name
          Row(
            children: [
              PersonAvatar(personName: present['present_who'] ?? '', radius: 9),
              const SizedBox(width: 4),
              Text(
                present['present_who'] ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.blackLight),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          if (present['present_other_conditions'] != null &&
              present['present_other_conditions'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: present['present_other_conditions']
                  .toString()
                  .split(', ')
                  .where((s) => s.isNotEmpty)
                  .map<Widget>((condition) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(condition, style: const TextStyle(fontSize: 10, color: AppColors.blackDark)),
                            const SizedBox(width: 3),
                            Text('○', style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildPresentFooter(Map<String, dynamic> present) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          buildStarRating(context, present['present_reaction'] ?? 0, size: 15),
          const Spacer(),
          const Icon(Icons.currency_yen, size: 16, color: AppColors.blackLight),
          const SizedBox(width: 2),
          Text(
            Utils.formatCurrency(present['present_price'] ?? 0),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.blackDark),
          ),
          const SizedBox(width: 2),
          const Text('（税込）', style: TextStyle(fontSize: 10, color: AppColors.blackLight)),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit(Map<String, dynamic> present) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PresentFormWidget(
          initialPresent: present,
          presentService: widget.presentService,
        ),
      ),
    );
    if (result == true) await _loadPresentList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showSentPresents ? '贈ったお菓子' : '貰ったお菓子',
          style: const TextStyle(fontSize: 18),
        ),
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
      body: Column(
        children: [
          _buildTypeToggle(),
          _buildFilterAndSortRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Text(
                          '右下の＋ボタンから登録してください',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: AdUtils.calculateListItemCount(
                            _filteredList.length),
                        itemBuilder: (context, index) {
                          if (AdUtils.shouldShowAdAt(index)) {
                            return AdUtils.buildAdBanner();
                          }
                          final itemIndex = AdUtils.getActualItemIndex(index);
                          if (itemIndex >= _filteredList.length) {
                            return const SizedBox.shrink();
                          }
                          return _buildPresentItem(_filteredList[itemIndex]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: AppColors.blackDark,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PresentFormWidget(
                presentService: widget.presentService,
                initialType: _showSentPresents ? 'sent' : 'received',
              ),
            ),
          );
          if (result == true) await _loadPresentList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PresentFilterDialog extends StatefulWidget {
  final List<Map<String, dynamic>> presentList;
  final Map<String, bool> currentFilterGenre;
  final Map<String, bool> currentFilterWho;
  final Map<String, bool> currentFilterReaction;
  final Map<String, bool> currentFilterOtherCondition;
  final double currentPriceMin;
  final double currentPriceMax;

  const PresentFilterDialog({
    super.key,
    required this.presentList,
    required this.currentFilterGenre,
    required this.currentFilterWho,
    required this.currentFilterReaction,
    required this.currentFilterOtherCondition,
    required this.currentPriceMin,
    required this.currentPriceMax,
  });

  @override
  State<PresentFilterDialog> createState() => _PresentFilterDialogState();
}

class _PresentFilterDialogState extends State<PresentFilterDialog> {
  late Map<String, bool> _tempFilterGenre;
  late Map<String, bool> _tempFilterWho;
  late Map<String, bool> _tempFilterReaction;
  late Map<String, bool> _tempFilterOtherCondition;
  late RangeValues _tempFilterPriceRange;
  Set<String> _selectedGenres = {};
  Set<String> _selectedOtherConditions = {};

  @override
  void initState() {
    super.initState();
    _tempFilterGenre = Map.from(widget.currentFilterGenre);
    _tempFilterWho = Map.from(widget.currentFilterWho);
    _tempFilterReaction = Map.from(widget.currentFilterReaction);
    _tempFilterOtherCondition = Map.from(widget.currentFilterOtherCondition);
    _tempFilterPriceRange =
        RangeValues(widget.currentPriceMin, widget.currentPriceMax);
    _selectedGenres = Set.from(
        _tempFilterGenre.keys.where((key) => _tempFilterGenre[key] == true));
    _selectedOtherConditions = Set.from(_tempFilterOtherCondition.keys
        .where((key) => _tempFilterOtherCondition[key] == true));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー部分
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'フィルタリング',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black54,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.greyLight),
            // コンテンツ部分
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGenreSelector(),
                    const SizedBox(height: 16),
                    _buildOtherConditionSelector(),
                    const SizedBox(height: 16),
                    _buildPriceFilter(),
                    const SizedBox(height: 16),
                    _buildWhoFilter(),
                    const SizedBox(height: 16),
                    _buildReactionFilter(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.greyLight),
            // ボタン部分
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: const Text(
                          'キャンセル',
                          style: TextStyle(
                            color: AppColors.blackLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(context).pop({
                          'filterGenre': _tempFilterGenre,
                          'filterWho': _tempFilterWho,
                          'filterReaction': _tempFilterReaction,
                          'filterOtherCondition': _tempFilterOtherCondition,
                          'filterPriceMin': _tempFilterPriceRange.start
                              .clamp(0, Constants.maxPriceFilter),
                          'filterPriceMax': _tempFilterPriceRange.end
                              .clamp(0, Constants.maxPriceFilter),
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: const Text(
                          '適用',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreSelector() {
    return CommonWidgets.buildGenreSelector(
      context: context,
      selectedGenres: _selectedGenres,
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedGenres = newSelection;
          // フィルター用の Map も更新
          _tempFilterGenre.clear();
          for (String genre in newSelection) {
            _tempFilterGenre[genre] = true;
          }
        });
      },
      multiSelect: true, // 複数選択可能
    );
  }

  Widget _buildOtherConditionSelector() {
    return CommonWidgets.buildOtherConditionSelector(
      context: context,
      selectedConditions: _selectedOtherConditions,
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedOtherConditions = newSelection;
          // フィルター用の Map も更新
          _tempFilterOtherCondition.clear();
          for (String condition in newSelection) {
            _tempFilterOtherCondition[condition] = true;
          }
        });
      },
      multiSelect: true, // 複数選択可能
    );
  }

  Widget _buildWhoFilter() {
    final uniqueWhoList = widget.presentList
        .map((p) => p['present_who'] as String?)
        .where((who) => who != null && who.isNotEmpty)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '相手',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: uniqueWhoList.map((who) {
            final isSelected = _tempFilterWho[who.toString()] ?? false;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(
                    () => _tempFilterWho[who.toString()] = !isSelected),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : AppColors.greyLight,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    who.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : AppColors.blackLight,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReactionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              '反応',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.blackLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: List.generate(5, (i) {
            final rating = i + 1;
            final isSelected = _tempFilterReaction[rating.toString()] ?? true;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(
                    () => _tempFilterReaction[rating.toString()] = !isSelected),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.greyDark : AppColors.greyLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        rating,
                        (index) => Icon(
                          Icons.star_rounded,
                          color: isSelected
                              ? AppColors.starColor
                              : AppColors.greyDark,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '金額範囲',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greyLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyMedium),
                    ),
                    child: Text(
                      _tempFilterPriceRange.start == 0
                          ? '指定しない'
                          : '¥${_tempFilterPriceRange.start.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blackLight,
                      ),
                    ),
                  ),
                  const Text(
                    '〜',
                    style: TextStyle(color: AppColors.blackLight, fontSize: 16),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyMedium),
                    ),
                    child: Text(
                      _tempFilterPriceRange.end >= 20000
                          ? '指定しない'
                          : '¥${_tempFilterPriceRange.end.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blackLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Theme.of(context).primaryColor,
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  inactiveTrackColor: AppColors.greyLight,
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: RangeSlider(
                  min: 0,
                  max: 20000,
                  divisions: 20,
                  values: RangeValues(
                    _tempFilterPriceRange.start.clamp(0, 20000),
                    _tempFilterPriceRange.end.clamp(0, 20000),
                  ),
                  onChanged: (values) =>
                      setState(() => _tempFilterPriceRange = values),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PresentFormWidget extends StatefulWidget {
  final Map<String, dynamic>? initialPresent;
  final PresentManagementService presentService;
  final String initialType;

  const PresentFormWidget({
    super.key,
    this.initialPresent,
    required this.presentService,
    this.initialType = 'sent',
  });

  @override
  State<PresentFormWidget> createState() => _PresentFormWidgetState();
}

class _PresentFormWidgetState extends State<PresentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  late DateTime _selectedDate;
  Set<String> _selectedGenres = {};
  Set<String> _selectedOtherConditions = {};
  int _presentReaction = 0;
  List<XFile> _pickedFiles = [];
  List<Uint8List> _webImages = [];
  List<String> _existingImageUrls = [];
  int _remainingChars = Constants.memoMaxLength;
  late String _presentType;
  List<String> _allWhoNames = [];
  bool _showWhoSuggestions = false;
  int? _whoIconIndex;
  final _whoFieldController = TextEditingController();
  final _whoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadAllWhoNames();
    _whoFocusNode.addListener(() {
      if (_whoFocusNode.hasFocus) {
        setState(() => _showWhoSuggestions = true);
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showWhoSuggestions = false);
        });
      }
    });
  }

  Future<void> _loadAllWhoNames() async {
    if (AuthService.instance.isLoggedIn) {
      try {
        final names = await widget.presentService.getWhoNamesFromSupabase();
        if (mounted) setState(() => _allWhoNames = names);
      } catch (_) {}
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final presentList = prefs.getStringList(Constants.presentListKey) ?? [];
    final names = <String>{};
    for (final item in presentList) {
      final data = Map<String, dynamic>.from(jsonDecode(item));
      final who = data['present_who'] as String?;
      if (who != null && who.isNotEmpty) names.add(who);
    }
    if (mounted) setState(() => _allWhoNames = names.toList()..sort());
  }

  void _initializeForm() {
    _presentType = widget.initialPresent?['present_type'] ?? widget.initialType;

    final fields = [
      'present_name',
      'present_brand',
      'present_price',
      'present_memo'
    ];

    for (final field in fields) {
      String value = widget.initialPresent?[field]?.toString() ?? '';
      if (field == 'present_price') {
        value = Utils.formatCurrency(widget.initialPresent?[field]);
      }
      _controllers[field] = TextEditingController(text: value);
    }

    final initialWho = widget.initialPresent?['present_who']?.toString() ?? '';
    _whoFieldController.text = initialWho;
    if (initialWho.isNotEmpty) {
      PersonIconService.getIconIndex(initialWho).then((idx) {
        if (mounted) setState(() => _whoIconIndex = idx);
      });
    }
    String? initialGenre = widget.initialPresent?['present_genre'];
    if (initialGenre != null && initialGenre.isNotEmpty) {
      _selectedGenres = Set.from(initialGenre.split(', ').where((s) => s.isNotEmpty));
    }
    String? initialOtherConditions =
        widget.initialPresent?['present_other_conditions'];
    if (initialOtherConditions != null && initialOtherConditions.isNotEmpty) {
      _selectedOtherConditions = Set.from(initialOtherConditions.split(', '));
    }
    _selectedDate = widget.initialPresent?['present_date'] != null
        ? DateTime.parse(widget.initialPresent!['present_date'])
        : DateTime.now();
    _presentReaction = widget.initialPresent?['present_reaction'] ?? 0;

    // 画像URLの初期化（複数対応）
    if (widget.initialPresent?['present_imageurl'] != null) {
      String imageUrl = widget.initialPresent!['present_imageurl'];
      _existingImageUrls = [imageUrl];
    }
    if (widget.initialPresent?['present_imageurl2'] != null) {
      _existingImageUrls.add(widget.initialPresent!['present_imageurl2']);
    }
    if (widget.initialPresent?['present_imageurl3'] != null) {
      _existingImageUrls.add(widget.initialPresent!['present_imageurl3']);
    }

    _controllers['present_memo']!.addListener(_updateRemainingChars);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _whoFieldController.dispose();
    _whoFocusNode.dispose();
    super.dispose();
  }

  void _updateRemainingChars() {
    setState(() {
      _remainingChars = Constants.memoMaxLength -
          _controllers['present_memo']!.text.characters.length;
    });
  }

  Future<void> _pickImage() async {
    if (_pickedFiles.length + _existingImageUrls.length >= 3) {
      Utils.showSnackBar(context, '画像は最大3枚まで選択できます');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _pickedFiles.add(pickedFile));
      if (kIsWeb) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() => _webImages.add(imageBytes));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      int totalImages = _existingImageUrls.length + _pickedFiles.length;
      if (index < _existingImageUrls.length) {
        // 既存画像の削除
        _existingImageUrls.removeAt(index);
      } else {
        // 新規画像の削除
        int newImageIndex = index - _existingImageUrls.length;
        _pickedFiles.removeAt(newImageIndex);
        if (kIsWeb && newImageIndex < _webImages.length) {
          _webImages.removeAt(newImageIndex);
        }
      }
    });
  }

  Widget _buildImageWidget() {
    final totalImages = _existingImageUrls.length + _pickedFiles.length;
    final hasImages = totalImages > 0;
    final containerHeight = hasImages ? 200.0 : 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: containerHeight,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorderColor),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.cardBackground,
          ),
          child: hasImages
              ? Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: totalImages,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: _buildImageAtIndex(index),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.errorColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (totalImages < 3)
                      Container(
                        height: 40,
                        width: double.infinity,
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greyMedium,
                            foregroundColor: AppColors.blackLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text('画像を追加 (${totalImages}/3)'),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: AppColors.greyDark,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greyMedium,
                          foregroundColor: AppColors.blackLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('画像を選択'),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        const Text(
          '画像は最大3枚まで登録できます。',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.blackLight,
          ),
        ),
      ],
    );
  }

  Widget _buildImageAtIndex(int index) {
    if (index < _existingImageUrls.length) {
      // 既存画像
      return CommonWidgets.buildImage(
          _existingImageUrls[index], widget.presentService);
    } else {
      // 新規画像
      int newImageIndex = index - _existingImageUrls.length;
      if (kIsWeb) {
        return Image.memory(_webImages[newImageIndex], fit: BoxFit.cover);
      } else {
        return Image.file(File(_pickedFiles[newImageIndex].path),
            fit: BoxFit.cover);
      }
    }
  }

  Widget _buildWhoField(String label) {
    final suggestions = _allWhoNames.where((name) {
      final query = _whoFieldController.text;
      return query.isEmpty || name.contains(query);
    }).toList();
    final whoName = _whoFieldController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: whoName.isEmpty ? null : () async {
                final result = await showDialog<int>(
                  context: context,
                  builder: (_) => PersonIconPickerDialog(
                    personName: whoName,
                    currentIndex: _whoIconIndex,
                  ),
                );
                if (result != null) {
                  await PersonIconService.saveIconIndex(whoName, result);
                  setState(() => _whoIconIndex = result);
                }
              },
              child: whoName.isEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.greyMedium,
                      child: const Icon(Icons.person, size: 20, color: AppColors.greyDark),
                    )
                  : _buildInlineAvatar(whoName),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _whoFieldController,
                focusNode: _whoFocusNode,
                decoration: CommonWidgets.buildInputDecoration(label, context: context),
                validator: (value) => (value == null || value.isEmpty) ? '必須項目です' : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (_showWhoSuggestions && suggestions.isNotEmpty)
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    leading: PersonAvatar(personName: suggestions[index], radius: 14),
                    title: Text(suggestions[index],
                        style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      _whoFieldController.text = suggestions[index];
                      setState(() => _showWhoSuggestions = false);
                      _whoFocusNode.unfocus();
                      // load icon index for selected person
                      PersonIconService.getIconIndex(suggestions[index]).then((idx) {
                        if (mounted) setState(() => _whoIconIndex = idx);
                      });
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInlineAvatar(String name) {
    if (_whoIconIndex != null && _whoIconIndex! >= 0 && _whoIconIndex! < kPersonIcons.length) {
      final def = kPersonIcons[_whoIconIndex!];
      return Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: def.bgColor,
            child: Text(def.emoji, style: const TextStyle(fontSize: 18)),
          ),
          _editBadge(),
        ],
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        _editBadge(),
      ],
    );
  }

  Widget _editBadge() => Positioned(
    bottom: -4,
    right: -8,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.blackDark.withOpacity(0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('編集', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w500)),
    ),
  );

  Widget _buildGenreSelector() {
    return CommonWidgets.buildGenreSelector(
      context: context,
      selectedGenres: _selectedGenres,
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedGenres = newSelection;
        });
      },
      multiSelect: true, // 複数選択可能
    );
  }

  Widget _buildOtherConditionSelector() {
    return CommonWidgets.buildOtherConditionSelector(
      context: context,
      selectedConditions: _selectedOtherConditions,
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedOtherConditions = newSelection;
        });
      },
      multiSelect: true, // 複数選択可能
    );
  }

  Future<void> _savePresent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // 新しい画像を保存
      List<String> newImageUrls = [];
      for (XFile pickedFile in _pickedFiles) {
        String? imageUrl =
            await widget.presentService.saveImageLocally(pickedFile);
        if (imageUrl != null) {
          newImageUrls.add(imageUrl);
        }
      }

      // 既存画像と新規画像を結合
      List<String> allImageUrls = [..._existingImageUrls, ...newImageUrls];

      final presentData = {
        'present_id': widget.initialPresent?['present_id'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'present_createdate': widget.initialPresent?['present_createdate'] ??
            DateTime.now().toIso8601String(),
        '_event_id': widget.initialPresent?['_event_id'],
        '_useritem_id': widget.initialPresent?['_useritem_id'],
        '_who_id': widget.initialPresent?['_who_id'],
        'present_type': _presentType,
        'present_name': _controllers['present_name']!.text,
        'present_brand': _controllers['present_brand']!.text,
        'present_imageurl': allImageUrls.isNotEmpty ? allImageUrls[0] : null,
        'present_imageurl2': allImageUrls.length > 1 ? allImageUrls[1] : null,
        'present_imageurl3': allImageUrls.length > 2 ? allImageUrls[2] : null,
        'present_price': int.tryParse(
                _controllers['present_price']!.text.replaceAll(',', '')) ??
            0,
        'present_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'present_who': _whoFieldController.text,
        'present_reaction': _presentReaction,
        'present_genre': _selectedGenres.join(', '),
        'present_other_conditions': _selectedOtherConditions.join(', '),
        'present_memo': _controllers['present_memo']!.text,
      };

      if (widget.initialPresent != null) {
        await widget.presentService.updatePresent(presentData);
      } else {
        await widget.presentService.savePresent(presentData);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('このデータを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.presentService
            .deletePresent(widget.initialPresent!['present_id']);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  void _showDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          height: 300,
          width: 300,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: AppColors.blackDark,
                    surface: AppColors.cardBackground,
                    onSurface: AppColors.blackDark,
                  ),
            ),
            child: SfDateRangePicker(
              view: DateRangePickerView.month,
              selectionMode: DateRangePickerSelectionMode.single,
              initialSelectedDate: _selectedDate,
              selectionColor: Theme.of(context).primaryColor,
              todayHighlightColor: Theme.of(context).primaryColor,
              onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                if (args.value is DateTime) {
                  setState(() => _selectedDate = args.value);
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.blackLight,
            ),
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(SearchType searchType) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ItemSearchDialog(searchType: searchType),
    );

    if (result != null) {
      setState(() {
        _controllers['present_name']!.text = result['item_name'] ?? '';
        _controllers['present_brand']!.text = result['item_brand'] ?? '';
        _controllers['present_price']!.text =
            Utils.formatCurrency(result['item_price']);
        String? genre = result['item_category'];
        if (genre != null && genre.isNotEmpty) {
          _selectedGenres = {genre};
        }
        if (result['item_imageurl'] != null &&
            result['item_imageurl'].toString().isNotEmpty) {
          _existingImageUrls = [result['item_imageurl']];
          _pickedFiles.clear();
          _webImages.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewRecord = widget.initialPresent == null;
    String title;
    if (!isNewRecord) {
      title = '編集';
    } else if (_presentType == 'sent') {
      title = '贈ったお菓子を記録';
    } else {
      title = '貰ったお菓子を記録';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        actions: [
          if (widget.initialPresent != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildFormTypeToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _buildFormToggleOption(
            label: '贈った',
            icon: Icons.card_giftcard,
            isSelected: _presentType == 'sent',
            onTap: () => setState(() => _presentType = 'sent'),
          ),
          _buildFormToggleOption(
            label: '貰った',
            icon: Icons.restaurant,
            isSelected: _presentType == 'received',
            onTap: () => setState(() => _presentType = 'received'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Theme.of(context).primaryColor : AppColors.blackLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : AppColors.blackLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final whoLabel = _presentType == 'sent' ? '贈った相手 *' : '贈ってくれた人 *';
    final nameLabel = _presentType == 'sent' ? '贈ったお菓子の名称 *' : '貰ったお菓子の名称 *';
    final reactionLabel = _presentType == 'sent' ? '相手の反応' : '評価';

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormTypeToggle(),
            TextFormField(
              controller: _controllers['present_name']!,
              decoration: CommonWidgets.buildInputDecoration(
                nameLabel,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchDialog(SearchType.name),
                ),
                context: context,
              ),
              validator: (value) => value!.isEmpty ? '必須項目です' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controllers['present_brand']!,
              decoration: CommonWidgets.buildInputDecoration(
                'ブランド・会社名 *',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchDialog(SearchType.brand),
                ),
                context: context,
              ),
              validator: (value) => value!.isEmpty ? '必須項目です' : null,
            ),
            const SizedBox(height: 24),
            _buildGenreSelector(),
            const SizedBox(height: 24),
            _buildOtherConditionSelector(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _controllers['present_price']!,
                    decoration: CommonWidgets.buildInputDecoration('金額', context: context),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorInputFormatter(),
                    ],
                  ),
                ),
                const Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Text('円',
                        style: TextStyle(
                            fontSize: 16,
                            color: AppColors.blackLight,
                            fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '画像',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blackLight,
                  ),
                ),
                const SizedBox(height: 8),
                _buildImageWidget(),
              ],
            ),
            const SizedBox(height: 24),
            _buildWhoField(whoLabel),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '日付',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blackLight,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDatePicker(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border.all(color: AppColors.inputBorderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.blackDark,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_month,
                          color: AppColors.blackLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  reactionLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blackLight,
                  ),
                ),
                const SizedBox(height: 8),
                CommonWidgets.buildReactionStar(
                  _presentReaction,
                  onTap: (starNumber) =>
                      setState(() => _presentReaction = starNumber),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controllers['present_memo']!,
              decoration: InputDecoration(
                labelText: 'メモ',
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.blackLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.inputBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.inputBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
                counterText: '残り $_remainingChars 文字',
                counterStyle: const TextStyle(
                  color: AppColors.blackLight,
                  fontSize: 12,
                ),
              ),
              maxLength: 200,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePresent,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppColors.blackDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shadowColor: AppColors.shadowColor,
                      ),
                      child: const Text(
                        '保存',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greyMedium,
                        foregroundColor: AppColors.blackLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shadowColor: AppColors.shadowColor,
                      ),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (widget.initialPresent != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showDeleteConfirmation(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shadowColor: AppColors.shadowColor,
                        ),
                        child: const Text(
                          '削除',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int selectionIndex =
        newValue.text.length - newValue.selection.extentOffset;
    final parts = newValue.text.replaceAll(',', '');
    final formatter = NumberFormat('#,###', 'en_US');
    final parsed = int.tryParse(parts);
    final formatted = parsed != null ? formatter.format(parsed) : parts;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length - selectionIndex,
      ),
    );
  }
}

class ItemSearchDialog extends StatefulWidget {
  final SearchType searchType;

  const ItemSearchDialog({super.key, required this.searchType});

  @override
  _ItemSearchDialogState createState() => _ItemSearchDialogState();
}

class _ItemSearchDialogState extends State<ItemSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _hasSearched = true;
      _isLoading = true;
    });
    try {
      String searchField =
          widget.searchType == SearchType.name ? 'item_name' : 'item_brand';
      final allItems = await Supabase.instance.client
          .from('item')
          .select()
          .limit(5000);
      final normalizedQuery = Utils.normalizeString(query);

      final filteredResults = List<Map<String, dynamic>>.from(allItems)
          .where((data) {
            final targetField = data[searchField];
            if (targetField == null) return false;

            final normalizedTarget =
                Utils.normalizeString(targetField.toString());
            return normalizedTarget.contains(normalizedQuery);
          })
          .toList();

      presentLogger.info('検索結果件数: ${filteredResults.length}');

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isLoading = false;
        });
      }
    } catch (error) {
      presentLogger.severe('検索エラー詳細: $error');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('検索エラー: ${error.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.searchType == SearchType.name ? 'お菓子名で検索' : 'ブランド・会社名で検索',
        style: const TextStyle(
          color: AppColors.blackLight,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '検索',
                labelStyle: const TextStyle(
                  color: AppColors.blackLight,
                  fontSize: 14,
                ),
                suffixIcon:
                    const Icon(Icons.search, color: AppColors.blackLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.inputBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.inputBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : !_hasSearched
                      ? const Center(
                          child: Text(
                            '検索してください',
                            style: TextStyle(
                              color: AppColors.blackLight,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : _searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                '検索結果がありません',
                                style: TextStyle(
                                  color: AppColors.blackLight,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  color: AppColors.cardBackground,
                                  elevation: 2,
                                  shadowColor: AppColors.shadowColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: item['item_imageurl'] != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Image.network(
                                              item['item_imageurl'],
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.greyLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 30,
                                                    color: AppColors.greyDark,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: AppColors.greyLight,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.image,
                                              size: 30,
                                              color: AppColors.greyDark,
                                            ),
                                          ),
                                    title: Text(
                                      item['item_name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.blackDark,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['item_brand'] ?? '',
                                            style: const TextStyle(
                                              color: AppColors.blackLight,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '¥${Utils.formatCurrency(item['item_price'])}',
                                            style: const TextStyle(
                                              color: AppColors.blackDark,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (item['item_company'] != null &&
                                              item['item_company']
                                                  .toString()
                                                  .isNotEmpty)
                                            Text(
                                              item['item_company'],
                                              style: const TextStyle(
                                                color: AppColors.blackLight,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop(item);
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.blackLight,
          ),
          child: const Text('キャンセル'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
