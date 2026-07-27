import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/view/home.dart';
import 'package:alamode_app/view/memo.dart';
import 'package:alamode_app/services/favorite_service.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final currencyFormat = NumberFormat('#,###');
  List<Map<String, dynamic>> _itemList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isOfflineFallback = false;
  static const String _favoriteItemsCacheKey = 'favorite_items_cache';

  // フィルター・ソート用の変数（homeと同じ）
  String _sortBy = 'item_price_low';
  Map<String, bool> _filterGenre = {};
  double _filterPriceMin = 0;
  double _filterPriceMax = 20000;
  bool _filterIndividualWrapping = false;
  bool _filterRoomTemperature = false;
  bool _filterOnline = false;
  bool _filterAlcohol = false;
  bool _filterLimited = false;
  bool _filterPhysicalStore = false;
  //double _filterRatingMin = 1;
  //double _filterRatingMax = 5;
  // 並び替えオプション（homeと同じ）
  static const List<Map<String, String>> _sortOptions = [
    //   {'value': 'item_rating', 'label': '評価が高い順'},
    {'value': 'item_price_low', 'label': '価格の安い順'},
    {'value': 'item_price_high', 'label': '価格の高い順'},
    {'value': 'item_brand', 'label': '商品名順'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFavoriteItems();
  }

  bool _isLoading = false;

  Future<void> _loadFavoriteItems() async {
    if (_isLoading) return;
    _isLoading = true;

    final favoriteIds = await _getFavoriteItems();
    if (favoriteIds.isEmpty) {
      setState(() {
        _itemList = [];
        _applyFiltersAndSort();
      });
      _isLoading = false;
      return;
    }

    try {
      final data = await supabase
          .from('item')
          .select()
          .inFilter('item_id', favoriteIds);

      final fetchedIds = data.map((d) => d['item_id'].toString()).toSet();
      final invalidIds = favoriteIds.where((id) => !fetchedIds.contains(id)).toList();

      if (invalidIds.isNotEmpty) {
        await FavoriteService.instance.removeFavorites(invalidIds);
      }

      final items = List<Map<String, dynamic>>.from(data);
      setState(() {
        _itemList = items;
        _isOfflineFallback = false;
        _applyFiltersAndSort();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoriteItemsCacheKey, jsonEncode(items));
    } catch (e) {
      // オフライン等で取得できない場合、直近成功時にキャッシュした商品データの
      // うち現在お気に入り登録されているものだけを表示にフォールバックする。
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_favoriteItemsCacheKey);
      if (cached != null) {
        final cachedItems = (jsonDecode(cached) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((item) => favoriteIds.contains(item['item_id']?.toString()))
            .toList();
        if (cachedItems.isNotEmpty) {
          setState(() {
            _itemList = cachedItems;
            _isOfflineFallback = true;
            _applyFiltersAndSort();
          });
        }
      }
      // キャッシュも無い場合は既存の表示（前回ロード分）を維持する
    }
    _isLoading = false;
  }

  void _applyFiltersAndSort() {
    _filteredList = _itemList.where((item) {
      // 価格フィルター
      final price = (item['item_price10percent'] as num?)?.toDouble() ?? 0;
      if (price < _filterPriceMin || price > _filterPriceMax) {
        return false;
      }

      // カテゴリーフィルター
      if (_filterGenre.isNotEmpty) {
        final selectedGenres = _filterGenre.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
        if (selectedGenres.isNotEmpty) {
          final itemCategory = item['item_category'] as String?;
          if (itemCategory == null) return false;
          final itemGenres = itemCategory.split(',').map((e) => e.trim()).toList();
          if (!itemGenres.any((g) => selectedGenres.contains(g))) {
            return false;
          }
        }
      }

      if (_filterIndividualWrapping) {
        final value = item['item_individualwrapping'];
        if (value != "1" && value != 1 && value != true) return false;
      }

      if (_filterRoomTemperature) {
        final value = item['item_roomtemperature'];
        if (value != "1" && value != 1 && value != true) return false;
      }

      if (_filterOnline) {
        final value = item['item_online'];
        if (value != "1" && value != 1 && value != true) return false;
      }

      if (_filterAlcohol) {
        final value = item['item_alcohol'];
        if (value != "1" && value != 1 && value != true) return false;
      }

      if (_filterLimited) {
        final value = item['item_limited'];
        if (value != "1" && value != 1 && value != true) return false;
      }

      if (_filterPhysicalStore) {
        final value = item['item_physicalstore'];
        if (value != "1" && value != 1 && value != true) return false;
      }

      return true;
    }).toList();

    // ソート
    _filteredList.sort((a, b) {
      switch (_sortBy) {
/*        case 'item_rating':
          return (b['item_rating'] ?? 0).compareTo(a['item_rating'] ?? 0);*/
        case 'item_price_low':
          return (a['item_price10percent'] ?? 0).compareTo(b['item_price10percent'] ?? 0);
        case 'item_price_high':
          return (b['item_price10percent'] ?? 0).compareTo(a['item_price10percent'] ?? 0);
        case 'item_brand':
          return (a['item_name'] ?? '').compareTo(b['item_name'] ?? '');
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
        currentFilterGenre: _filterGenre,
        currentPriceMin: _filterPriceMin,
        currentPriceMax: _filterPriceMax,
        currentIndividualWrapping: _filterIndividualWrapping,
        currentRoomTemperature: _filterRoomTemperature,
        currentOnline: _filterOnline,
        currentAlcohol: _filterAlcohol,
        currentLimited: _filterLimited,
        currentPhysicalStore: _filterPhysicalStore,
/*        currentFilterRatingMin: _filterRatingMin,
        currentFilterRatingMax: _filterRatingMax, */
        isAllTab: true, // お気に入りではカテゴリーフィルターを表示
      ),
    );
    if (result != null) {
      setState(() {
        _filterGenre = result['filterGenre'];
        _filterPriceMin = result['filterPriceMin'];
        _filterPriceMax = result['filterPriceMax'];
        _filterIndividualWrapping = result['filterIndividualWrapping'] ?? false;
        _filterRoomTemperature = result['filterRoomTemperature'] ?? false;
        _filterOnline = result['filterOnline'] ?? false;
        _filterAlcohol = result['filterAlcohol'] ?? false;
        _filterLimited = result['filterLimited'] ?? false;
        _filterPhysicalStore = result['filterPhysicalStore'] ?? false;
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
    final hasOtherFilter = _filterIndividualWrapping ||
        _filterRoomTemperature ||
        _filterOnline ||
        _filterAlcohol ||
        _filterLimited ||
        _filterPhysicalStore;
//    final hasRatingFilter = _filterRatingMin > 1 || _filterRatingMax < 5;
    return hasGenreFilter || hasPriceFilter || hasOtherFilter /*|| hasRatingFilter*/;
  }

  // homeからアクティブフィルターチップを借用
  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    // カテゴリーフィルター
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

    if (_filterIndividualWrapping) {
      filterChips.add(_buildFilterChip(
        label: CommonWidgets.conditionLabels['個包装']!['yes']!,
        onRemove: () {
          setState(() {
            _filterIndividualWrapping = false;
          });
          _applyFiltersAndSort();
        },
      ));
    }

    if (_filterRoomTemperature) {
      filterChips.add(_buildFilterChip(
        label: CommonWidgets.conditionLabels['常温']!['yes']!,
        onRemove: () {
          setState(() {
            _filterRoomTemperature = false;
          });
          _applyFiltersAndSort();
        },
      ));
    }

    if (_filterOnline) {
      filterChips.add(_buildFilterChip(
        label: CommonWidgets.conditionLabels['オンライン購入']!['yes']!,
        onRemove: () {
          setState(() {
            _filterOnline = false;
          });
          _applyFiltersAndSort();
        },
      ));
    }

    if (_filterAlcohol) {
      filterChips.add(_buildFilterChip(
        label: CommonWidgets.conditionLabels['洋酒']!['yes']!,
        onRemove: () {
          setState(() {
            _filterAlcohol = false;
          });
          _applyFiltersAndSort();
        },
      ));
    }

    if (_filterLimited) {
      filterChips.add(_buildFilterChip(
        label: CommonWidgets.conditionLabels['限定']!['yes']!,
        onRemove: () {
          setState(() {
            _filterLimited = false;
          });
          _applyFiltersAndSort();
        },
      ));
    }

    if (_filterPhysicalStore) {
      filterChips.add(_buildFilterChip(
        label: CommonWidgets.conditionLabels['実店舗']!['yes']!,
        onRemove: () {
          setState(() {
            _filterPhysicalStore = false;
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
        color: AppColors.greyLight.withValues(alpha: 0.8),
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
        child: Column(
          children: [
            if (_isOfflineFallback)
              Container(
                width: double.infinity,
                color: AppColors.greyLight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Text(
                  'オフラインのため最新の情報を取得できません。前回表示時のデータを表示しています。',
                  style: TextStyle(fontSize: 11, color: AppColors.blackLight),
                ),
              ),
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
                                    ? Theme.of(context).primaryColor
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'まだお気に入りがありません',
                            style: TextStyle(fontSize: 15, color: AppColors.blackLight),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Search からハートを押して登録できます',
                            style: TextStyle(fontSize: 12, color: AppColors.greyDark),
                          ),
                        ],
                      ),
                    )
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
                          itemId: item['item_id']?.toString() ?? '',
                          index: itemIndex,
                          onFavoriteChanged: () {
                            _loadFavoriteItems();
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ItemDetailScreen(itemId: item['item_id']?.toString() ?? ''),
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
    return FavoriteService.instance.getFavoriteIds();
  }
}
