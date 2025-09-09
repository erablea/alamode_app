import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/view/home.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final currencyFormat = NumberFormat('#,###');
  late Future<List<String>> _favoriteItemsFuture;
  List<Map<String, dynamic>> _itemList = [];
  List<Map<String, dynamic>> _filteredList = [];

  // フィルター・ソート用の変数（homeと同じ）
  String _sortBy = 'item_rating';
  Map<String, bool> _filterGenre = {};
  double _filterPriceMin = 0;
  double _filterPriceMax = 20000;
  double _filterRatingMin = 1;
  double _filterRatingMax = 5;

  // 並び替えオプション（homeと同じ）
  static const List<Map<String, String>> _sortOptions = [
    //   {'value': 'item_rating', 'label': '評価が高い順'},
    {'value': 'item_price_low', 'label': '価格の安い順'},
    {'value': 'item_price_high', 'label': '価格の高い順'},
    {'value': 'item_brand', 'label': 'ブランド名順'},
  ];

  @override
  void initState() {
    super.initState();
    _favoriteItemsFuture = _getFavoriteItems();
    _loadFavoriteItems();
  }

  Future<void> _loadFavoriteItems() async {
    final favoriteIds = await _getFavoriteItems();
    List<Map<String, dynamic>> items = [];

    for (String itemId in favoriteIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('item')
            .doc(itemId)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          items.add(data);
        }
      } catch (e) {
        // エラーハンドリング
      }
    }

    setState(() {
      _itemList = items;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    _filteredList = _itemList.where((item) {
      // 価格フィルター
      final price = (item['item_price'] as num?)?.toDouble() ?? 0;
      if (price < _filterPriceMin || price > _filterPriceMax) {
        return false;
      }

/*     // 評価フィルター
      final rating = (item['item_rating'] as num?)?.toDouble() ?? 0;
      if (rating < _filterRatingMin || rating > _filterRatingMax) {
        return false;
      }
*/
      // ジャンルフィルター
      if (_filterGenre.isNotEmpty) {
        final selectedGenres = _filterGenre.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
        if (selectedGenres.isNotEmpty) {
          final itemGenre = item['item_genre'] as String?;
          if (itemGenre == null || !selectedGenres.contains(itemGenre)) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // ソート
    _filteredList.sort((a, b) {
      switch (_sortBy) {
/*        case 'item_rating':
          return (b['item_rating'] ?? 0).compareTo(a['item_rating'] ?? 0);*/
        case 'item_price_low':
          return (a['item_price'] ?? 0).compareTo(b['item_price'] ?? 0);
        case 'item_price_high':
          return (b['item_price'] ?? 0).compareTo(a['item_price'] ?? 0);
        case 'item_brand':
          return (a['item_brand'] ?? '').compareTo(b['item_brand'] ?? '');
        default:
          return 0;
      }
    });

    setState(() {});
  }

  Future<void> _openFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => HomeFilterDialog(
        itemList: _itemList,
        currentFilterGenre: _filterGenre,
        currentPriceMin: _filterPriceMin,
        currentPriceMax: _filterPriceMax,
/*        currentFilterRatingMin: _filterRatingMin,
        currentFilterRatingMax: _filterRatingMax, */
        isAllTab: true, // お気に入りではジャンルフィルターを表示
      ),
    );
    if (result != null) {
      setState(() {
        _filterGenre = result['filterGenre'];
        _filterPriceMin = result['filterPriceMin'];
        _filterPriceMax = result['filterPriceMax'];
/*        _filterRatingMin = result['filterRatingMin'];
        _filterRatingMax = result['filterRatingMax'];*/
      });
      _applyFiltersAndSort();
    }
  }

  // homeから使用するフィルターチップの表示判定
  bool _hasActiveFilters() {
    final hasGenreFilter = _filterGenre.values.any((selected) => selected);
    final hasPriceFilter = _filterPriceMin > 0 || _filterPriceMax < 20000;
//    final hasRatingFilter = _filterRatingMin > 1 || _filterRatingMax < 5;
    return hasGenreFilter || hasPriceFilter /*|| hasRatingFilter*/;
  }

  // homeからアクティブフィルターチップを借用
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

    // 価格フィルター
    if (_filterPriceMin > 0 || _filterPriceMax < 20000) {
      String priceLabel = '';
      if (_filterPriceMin > 0 && _filterPriceMax < 20000) {
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
            _filterPriceMax = 20000;
          });
          _applyFiltersAndSort();
        },
      ));
    }

/*    // 評価フィルター
    if (_filterRatingMin > 1 || _filterRatingMax < 5) {
      String ratingLabel = '';
      if (_filterRatingMin > 1 && _filterRatingMax < 5) {
        ratingLabel =
            '★${_filterRatingMin.toInt()} - ★${_filterRatingMax.toInt()}';
      } else if (_filterRatingMin > 1) {
        ratingLabel = '★${_filterRatingMin.toInt()}以上';
      } else {
        ratingLabel = '★${_filterRatingMax.toInt()}以下';
      }

      filterChips.add(_buildFilterChip(
        label: ratingLabel,
        onRemove: () {
          setState(() {
            _filterRatingMin = 1;
            _filterRatingMax = 5;
          });
          _applyFiltersAndSort();
        },
      ));
    }
*/
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入り', style: TextStyle(fontSize: 18)),
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
        child: Column(
          children: [
            // フィルター・ソート行（homeから借用）
            if (_itemList.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.sort,
                        color: AppColors.blackLight,
                      ),
                      tooltip: '並び替え',
                      onSelected: (value) {
                        setState(() => _sortBy = value);
                        _applyFiltersAndSort();
                      },
                      itemBuilder: (context) => _sortOptions.map((option) {
                        return PopupMenuItem<String>(
                          value: option['value'],
                          child: Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 16,
                                color: _sortBy == option['value']
                                    ? AppColors.primaryColor
                                    : Colors.transparent,
                              ),
                              const SizedBox(width: 8),
                              Text(option['label']!,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: _filteredList.isEmpty
                  ? const Center(
                      child: Text(
                      'Search画面からお気に入りを登録してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ))
                  : ListView.builder(
                      itemCount:
                          AdUtils.calculateListItemCount(_filteredList.length),
                      itemBuilder: (context, index) {
                        if (AdUtils.shouldShowAdAt(index)) {
                          return AdUtils.buildAdBanner();
                        }
                        final itemIndex = AdUtils.getActualItemIndex(index);
                        if (itemIndex >= _filteredList.length) {
                          return const SizedBox.shrink();
                        }
                        final item = _filteredList[itemIndex];
                        return ItemCard(
                          item: item,
                          itemId: item['id'],
                          index: itemIndex,
                          onFavoriteChanged: () {
                            _loadFavoriteItems();
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ItemDetailScreen(itemId: item['id']),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _getFavoriteItems() async {
    // ローカルストレージからお気に入りを取得
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('favorite') ?? [];
  }
}
