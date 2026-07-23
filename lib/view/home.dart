import 'dart:async' as async;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:alamode_app/main.dart';
import 'package:alamode_app/view/memo.dart';
import 'package:alamode_app/widgets/category_placeholder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:alamode_app/services/favorite_service.dart';
import 'package:alamode_app/services/item_image_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<String> _tabs = ['all'];
  late TabController _tabController;
  late PageController _pageViewController;
  late ScrollController _scrollController;
  bool _showLeftArrow = false;
  bool _showRightArrow = true; // 初期状態では右矢印を表示
  bool _isLoadingGenres = true;

  @override
  void initState() {
    super.initState();
    _loadGenresFromSupabase();
  }

  Future<void> _loadGenresFromSupabase() async {
    try {
      final data = await supabase.from('item').select('item_category');
      Set<String> genres = {};

      for (var item in data) {
        final genreString = item['item_category'] as String?;
        if (genreString != null && genreString.isNotEmpty) {
          final genreList =
              genreString.split(',').map((e) => e.trim()).toList();
          genres.addAll(genreList);
        }
      }

      final sortedGenres = genres.toList()..sort();

      setState(() {
        _tabs = ['all', ...sortedGenres];
        _isLoadingGenres = false;
        // カテゴリー読み込み完了後にコントローラーを初期化
        _initializeControllers();
      });
    } catch (e) {
      print('Error loading genres: $e');
      setState(() {
        _isLoadingGenres = false;
        _initializeControllers();
      });
    }
  }

  void _initializeControllers() {
    _tabController = TabController(length: _tabs.length, vsync: this);
    _pageViewController = PageController();
    _scrollController = ScrollController();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
        _pageViewController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final tabWidth = 80.0;
            final targetOffset = _tabController.index * tabWidth -
                (MediaQuery.of(context).size.width / 2 - tabWidth / 2);
            final clampedOffset = targetOffset.clamp(
                0.0, _scrollController.position.maxScrollExtent);
            if ((clampedOffset - _scrollController.offset).abs() > 10) {
              _scrollController.animateTo(
                clampedOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        });
      }
    });

    _initScrollController();
    _checkInitialArrowState();
  }

  void _initScrollController() {
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _showLeftArrow = _scrollController.offset > 0;
          _showRightArrow = _scrollController.hasClients &&
              _scrollController.offset <
                  _scrollController.position.maxScrollExtent;
        });
      }
    });
  }

  void _checkInitialArrowState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        setState(() {
          _showRightArrow = _scrollController.position.maxScrollExtent > 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageViewController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingGenres) {
      return Scaffold(
        appBar: AppBar(toolbarHeight: 35.0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 35.0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.0),
          child: _buildTabBarWithArrow(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageViewController,
        onPageChanged: (index) {
          if (!_tabController.indexIsChanging) {
            _tabController.animateTo(index);
          }
        },
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          return ItemList(key: ValueKey(_tabs[index]), genre: _tabs[index]);
        },
      ),
    );
  }

  Widget _buildTabBarWithArrow(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 32.0,
          width: double.infinity,
          color: Colors.white,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.asMap().entries.map((entry) {
                    return _buildTab(entry.key, entry.value);
                  }).toList(),
                ),
              ),
              if (_showLeftArrow) _buildArrowButton(true),
              if (_showRightArrow) _buildArrowButton(false),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 1.0,
            color: AppColors.greyMedium,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 2.0,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.greyMedium.withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String name) {
    bool isSelected = _tabController.index == index;
    bool isAllTab = index == 0;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        _updateArrowState();
      },
      child: Container(
        height: 32.0,
        padding: EdgeInsets.symmetric(horizontal: isAllTab ? 15.0 : 10.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: isAllTab ? 0.0 : 2.0,
            bottom: 0.0, // 下の余白を統一
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: isAllTab ? 16.0 : 14.0, // 'all'のみ大きく
              fontWeight: FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  // 左端の矢印マーク
  Widget _buildArrowButton(bool isLeft) {
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () => _scrollTabBar(isLeft),
        child: Container(
          width: 40,
          alignment: Alignment.center,
          child: Icon(
            isLeft ? Icons.arrow_circle_left : Icons.arrow_circle_right,
            color: AppColors.blackLight.withValues(alpha: 0.7),
            size: 24,
          ),
        ),
      ),
    );
  }

  // 右端の矢印マーク
  void _scrollTabBar(bool isLeft) {
    const double scrollAmount = 100.0;
    final double currentOffset = _scrollController.offset;
    final double maxScrollExtent = _scrollController.position.maxScrollExtent;

    final double targetOffset = isLeft
        ? (currentOffset - scrollAmount).clamp(0.0, maxScrollExtent)
        : (currentOffset + scrollAmount).clamp(0.0, maxScrollExtent);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateArrowState() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        setState(() {
          _showLeftArrow = _scrollController.offset > 0;
          _showRightArrow = _scrollController.offset <
              _scrollController.position.maxScrollExtent;
        });
      }
    });
  }
}

/*  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '評価',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        RangeSlider(
          min: 1,
          max: 5,
          divisions: 4,
          values: _tempFilterRatingRange,
          onChanged: (values) =>
              setState(() => _tempFilterRatingRange = values),
        ),
      ],
    );
  }
*/
class ItemList extends StatefulWidget {
  final String genre;
  const ItemList({super.key, required this.genre});

  @override
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemList>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _cachedDocs;
  final currencyFormat = NumberFormat('#,###');
  String _sortBy = 'display_order';
  static Map<String, bool> _globalFilterGenre = {};
  static double _globalFilterPriceMin = 0;
  static double _globalFilterPriceMax = 20000;
  static bool _globalFilterIndividualWrapping = false;
  static bool _globalFilterRoomTemperature = false;
  static bool _globalFilterOnline = false;
  static bool _globalFilterAlcohol = false;
  @override
  bool get wantKeepAlive => true;

// ローカル変数をglobal変数で初期化
  Map<String, bool> get _filterGenre => _globalFilterGenre;
  set _filterGenre(Map<String, bool> value) => _globalFilterGenre = value;

  double get _filterPriceMin => _globalFilterPriceMin;
  set _filterPriceMin(double value) => _globalFilterPriceMin = value;

  double get _filterPriceMax => _globalFilterPriceMax;
  set _filterPriceMax(double value) => _globalFilterPriceMax = value;

  bool get _filterIndividualWrapping => _globalFilterIndividualWrapping;
  set _filterIndividualWrapping(bool value) =>
      _globalFilterIndividualWrapping = value;

  bool get _filterRoomTemperature => _globalFilterRoomTemperature;
  set _filterRoomTemperature(bool value) =>
      _globalFilterRoomTemperature = value;

  bool get _filterOnline => _globalFilterOnline;
  set _filterOnline(bool value) => _globalFilterOnline = value;

  bool get _filterAlcohol => _globalFilterAlcohol;
  set _filterAlcohol(bool value) => _globalFilterAlcohol = value;

// 並び替えオプション
  static const List<Map<String, String>> _sortOptions = [
    //   {'value': 'item_rating', 'label': '評価が高い順'},
    {'value': 'display_order', 'label': 'おすすめ順'},
    {'value': 'item_price_low', 'label': '価格の安い順'},
    {'value': 'item_price_high', 'label': '価格の高い順'},
    {'value': 'brand_name', 'label': 'ブランド名順'},
  ];

// ソートフィールドを取得
  String get _sortField {
    if (_sortBy.startsWith('item_price')) return 'item_price';
    if (_sortBy == 'display_order') return 'item_display_order';
    return _sortBy;
  }

  bool get _sortDescending {
    switch (_sortBy) {
      case 'item_price_high':
        return true; // 降順
      case 'brand_name':
      case 'item_price_low':
      case 'display_order':
        return false; // 昇順
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildFilterAndSortRow(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _cachedDocs == null
                ? FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getFilteredQuery(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('エラーが発生しました'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('coming soon'));
                      }

                      _cachedDocs = snapshot.data!;
                      return _buildItemList(_cachedDocs!);
                    },
                  )
                : _buildItemList(_cachedDocs!),
          ),
        ),
      ],
    );
  }

  async.Future<void> _handleRefresh() async {
    setState(() {
      _cachedDocs = null; // キャッシュをクリア
    });

    await async.Future.delayed(const Duration(milliseconds: 500)); // ローディング表示
  }

  Widget _buildItemList(List<Map<String, dynamic>> docs) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _applyClientSideFilters(docs),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('エラーが発生しました'));
        }

        final filteredDocs = snapshot.data ?? [];

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('条件に合う商品が見つかりません'));
        }

        return ListView.builder(
          itemCount: AdUtils.calculateListItemCount(filteredDocs.length),
          itemBuilder: (context, index) {
            if (AdUtils.shouldShowAdAt(index)) {
              return AdUtils.buildAdBanner();
            }
            final itemIndex = AdUtils.getActualItemIndex(index);
            if (itemIndex >= filteredDocs.length) {
              return const SizedBox.shrink();
            }
            final item = filteredDocs[itemIndex];
            // ignore: avoid_print
            return ItemCard(
              item: item,
              itemId: item['item_id']?.toString() ?? '',
              index: itemIndex,
              onFavoriteChanged: () {},
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(itemId: item['item_id']?.toString() ?? ''),
                  ),
                );
                if (result == true) setState(() {});
              },
            );
          },
        );
      },
    );
  }

  async.Future<List<Map<String, dynamic>>> _applyClientSideFilters(
      List<Map<String, dynamic>> docs) async {
    List<Map<String, dynamic>> filteredDocs = [];
    for (var item in docs) {
// カテゴリーフィルタリング（特定のカテゴリータブの場合）
      if (widget.genre != 'all') {
        final category = item['item_category'] as String? ?? '';
        final categoryList = category.split(',').map((e) => e.trim()).toList();
        if (!categoryList.contains(widget.genre)) {
          continue;
        }
      }

      // 追加のカテゴリーフィルタリング（allタブでフィルタが適用されている場合）
      if (widget.genre == 'all' && _filterGenre.isNotEmpty) {
        final selectedGenres = _filterGenre.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
        if (selectedGenres.isNotEmpty) {
          final category = item['item_category'] as String? ?? '';
          final categoryList =
              category.split(',').map((e) => e.trim()).toList();
          bool hasMatchingGenre =
              selectedGenres.any((g) => categoryList.contains(g));
          if (!hasMatchingGenre) {
            continue;
          }
        }
      }

      // 価格フィルター
      final price = (item['item_price'] as num?)?.toDouble() ?? 0;
      if (price < _filterPriceMin || price > _filterPriceMax) {
        continue;
      }

      if (_filterIndividualWrapping) {
        final value = item['item_individualwrapping'];
        if (value != "1" && value != 1 && value != true) continue;
      }

      if (_filterRoomTemperature) {
        final value = item['item_roomtemperature'];
        if (value != "1" && value != 1 && value != true) continue;
      }

      if (_filterOnline) {
        final value = item['item_online'];
        if (value != "1" && value != 1 && value != true) continue;
      }

      if (_filterAlcohol) {
        final value = item['item_alcohol'];
        if (value != "1" && value != 1 && value != true) continue;
      }

      filteredDocs.add(item);
    }

    return filteredDocs;
  }

  Widget _buildFilterAndSortRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // アクティブフィルターの横スクロール表示
          if (_hasActiveFilters())
            Expanded(child: _buildActiveFilters())
          else
            const Expanded(child: SizedBox()),
          // フィルター・ソートボタン行
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: const Icon(
                    Icons.filter_list_alt,
                    color: AppColors.blackLight,
                  ),
                  tooltip: 'フィルタリング',
                  onPressed: _openFilterDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.sort,
                    color: AppColors.blackLight,
                  ),
                  tooltip: '並び替え',
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                      _cachedDocs = null;
                    });
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    final hasGenreFilter = _filterGenre.values.any((selected) => selected);
    final hasPriceFilter = _filterPriceMin > 0 || _filterPriceMax < 20000;
    final hasOtherFilter =
        _filterIndividualWrapping ||
            _filterRoomTemperature ||
            _filterOnline ||
            _filterAlcohol;
//    final hasRatingFilter = _filterRatingMin > 1 || _filterRatingMax < 5;
    return hasGenreFilter || hasPriceFilter || hasOtherFilter /*|| hasRatingFilter*/;
  }

  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    // カテゴリーフィルター（allタブの時のみ表示）
    if (widget.genre == 'all') {
      _filterGenre.forEach((genre, isSelected) {
        if (isSelected) {
          filterChips.add(_buildFilterChip(
            label: genre,
            onRemove: () {
              setState(() {
                _filterGenre[genre] = false;
              });
            },
          ));
        }
      });
    }

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

  async.Future<List<Map<String, dynamic>>> _getFilteredQuery() async {
    final data = await supabase
        .from('item')
        .select()
        .order(_sortField, ascending: !_sortDescending);
    return data;
  }

  async.Future<void> _openFilterDialog() async {
    // Supabaseからデータ取得
    final data = await supabase.from('item').select();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => HomeFilterDialog(
        itemList: data,
        currentFilterGenre: _filterGenre, // 常に現在のフィルター状態を渡す
        currentPriceMin: _filterPriceMin,
        currentPriceMax: _filterPriceMax,
        currentIndividualWrapping: _filterIndividualWrapping,
        currentRoomTemperature: _filterRoomTemperature,
        currentOnline: _filterOnline,
        currentAlcohol: _filterAlcohol,
        isAllTab: widget.genre == 'all', // allタブかどうかを新しいパラメータで渡す
      ),
    );
    if (result != null) {
      setState(() {
        if (widget.genre == 'all') {
          _filterGenre = result['filterGenre'];
        }
        _filterPriceMin = result['filterPriceMin'];
        _filterPriceMax = result['filterPriceMax'];
        _filterIndividualWrapping = result['filterIndividualWrapping'] ?? false;
        _filterRoomTemperature = result['filterRoomTemperature'] ?? false;
        _filterOnline = result['filterOnline'] ?? false;
        _filterAlcohol = result['filterAlcohol'] ?? false;
        _cachedDocs = null;
      });
    }
  }
}

class ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String itemId;
  final int index;
  final VoidCallback? onFavoriteChanged;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.itemId,
    required this.index,
    this.onFavoriteChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(top: index == 0 ? 0 : 2, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.greyMedium, width: 0.5),
            bottom: BorderSide(color: AppColors.greyMedium, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyMedium.withValues(alpha: 0.8),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemHeader(context),
            _buildItemImages(context, item),
            _buildItemFooter(currencyFormat, item),
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader(BuildContext context) {
    final brandId = item['brand_id']?.toString();
    final category = item['item_category'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['item_name'] as String? ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 12, color: AppColors.blackLight),
              const SizedBox(width: 3),
              if (brandId != null)
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: supabase.from('brand').select().eq('brand_id', brandId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return Text(
                          snapshot.data!.first['brand_name'] as String? ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.blackLight),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                )
              else
                const Spacer(),
              if (category != null && category.isNotEmpty)
                ...category.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).map((c) =>
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.greyDark, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(c, style: const TextStyle(fontSize: 9, color: AppColors.blackLight)),
                  )
                ),
              const SizedBox(width: 6),
              SizedBox(
                width: 32,
                height: 28,
                child: FavoriteButton(
                  itemId: itemId,
                  onFavoriteChanged: onFavoriteChanged ?? () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildItemImages(BuildContext context, Map<String, dynamic> item) {
    final ownImages = ItemImageService.ownImageUrls(item);
    if (ownImages.isNotEmpty) {
      return _buildImageRow(context, ownImages);
    }
    return FutureBuilder<List<String>>(
      future: ItemImageService.resolveImageUrls(item),
      builder: (context, snapshot) {
        final imageUrls = snapshot.data ?? [];
        if (imageUrls.isEmpty) {
          return CategoryPlaceholder(
            category: item['item_category'] as String?,
            height: 90,
          );
        }
        return _buildImageRow(context, imageUrls);
      },
    );
  }

  Widget _buildImageRow(BuildContext context, List<String> imageUrls) {
    return Row(
      children: [
        for (int i = 0; i < imageUrls.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < imageUrls.length - 1 ? 1 : 0),
              height: 90,
              color: AppColors.warmWhite,
              child: CachedNetworkImage(
                imageUrl: imageUrls[i],
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.greyLight,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 40, color: AppColors.greyDark),
                  ),
                ),
                memCacheWidth: 240,
                memCacheHeight: 240,
                maxWidthDiskCache: 240,
                maxHeightDiskCache: 240,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemFooter(
      NumberFormat currencyFormat, Map<String, dynamic> item) {
    final price = item['item_price'] as num?;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          const Spacer(),
          Text(
            price != null ? '¥ ${currencyFormat.format(price)}' : '—',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.blackDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            '(税込)',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.blackLight,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeFilterDialog extends StatefulWidget {
  final List<Map<String, dynamic>> itemList;
  final Map<String, bool> currentFilterGenre;
  final double currentPriceMin;
  final double currentPriceMax;
  final bool currentIndividualWrapping;
  final bool currentRoomTemperature;
  final bool currentOnline;
  final bool currentAlcohol;
  final bool isAllTab;

  const HomeFilterDialog({
    super.key,
    required this.itemList,
    required this.currentFilterGenre,
    required this.currentPriceMin,
    required this.currentPriceMax,
    required this.currentIndividualWrapping,
    required this.currentRoomTemperature,
    required this.currentOnline,
    required this.currentAlcohol,
    required this.isAllTab,
  });

  @override
  State<HomeFilterDialog> createState() => _HomeFilterDialogState();
}

class _HomeFilterDialogState extends State<HomeFilterDialog> {
  late Map<String, bool> _tempFilterGenre;
  late RangeValues _tempFilterPriceRange;
  late bool _tempIndividualWrapping;
  late bool _tempRoomTemperature;
  late bool _tempOnline;
  late bool _tempAlcohol;
  late Future<List<String>> _genresFuture;
/*  late RangeValues _tempFilterRatingRange; */

  @override
  void initState() {
    super.initState();
    _tempFilterGenre = Map.from(widget.currentFilterGenre);
    _tempFilterPriceRange =
        RangeValues(widget.currentPriceMin, widget.currentPriceMax);
    _tempIndividualWrapping = widget.currentIndividualWrapping;
    _tempRoomTemperature = widget.currentRoomTemperature;
    _tempOnline = widget.currentOnline;
    _tempAlcohol = widget.currentAlcohol;
    _genresFuture = _getAvailableGenres();
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
              color: AppColors.blackDark.withValues(alpha: 0.15),
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
                      color: Theme.of(context).primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
                          color: AppColors.blackLight,
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
                    // カテゴリーフィルター（allタブの時のみ表示）
                    if (widget.isAllTab) ...[
                      _buildGenreFilter(),
                      const SizedBox(height: 24),
                    ],
                    _buildPriceFilter(),
                    const SizedBox(height: 24),
                    _buildOtherConditionsFilter(),
/*                    const SizedBox(height: 24),
                    _buildRatingFilter(), */
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
                          'filterPriceMin':
                              _tempFilterPriceRange.start.clamp(0, 20000),
                          'filterPriceMax':
                              _tempFilterPriceRange.end.clamp(0, 20000),
                          'filterIndividualWrapping': _tempIndividualWrapping,
                          'filterRoomTemperature': _tempRoomTemperature,
                          'filterOnline': _tempOnline,
                          'filterAlcohol': _tempAlcohol,
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

  Widget _buildGenreFilter() {
    return FutureBuilder<List<String>>(
      future: _genresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final genres = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カテゴリー',
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
              children: genres.map((genre) {
                final isSelected = _tempFilterGenre[genre] ?? false;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () =>
                        setState(() => _tempFilterGenre[genre] = !isSelected),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
      },
    );
  }

  Future<List<String>> _getAvailableGenres() async {
    try {
      final data = await supabase.from('item').select('item_category');
      Set<String> genres = {};

      for (var item in data) {
        final genreString = item['item_category'] as String?;
        if (genreString != null && genreString.isNotEmpty) {
          final genreList =
              genreString.split(',').map((e) => e.trim()).toList();
          genres.addAll(genreList);
        }
      }

      return genres.toList()..sort();
    } catch (e) {
      print('Error getting available genres: $e');
      return [];
    }
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
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
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
                          : '¥${NumberFormat('#,###').format(_tempFilterPriceRange.start.toInt())}',
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
                          : '¥${NumberFormat('#,###').format(_tempFilterPriceRange.end.toInt())}',
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
                  overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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

  Widget _buildOtherConditionsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'その他条件',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CommonWidgets.buildConditionChip(
                      context,
                      '個包装',
                      _tempIndividualWrapping ? 'yes' : 'unknown',
                      constrainText: true,
                      onTap: () => setState(
                          () => _tempIndividualWrapping = !_tempIndividualWrapping),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CommonWidgets.buildConditionChip(
                      context,
                      '常温',
                      _tempRoomTemperature ? 'yes' : 'unknown',
                      constrainText: true,
                      onTap: () => setState(
                          () => _tempRoomTemperature = !_tempRoomTemperature),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CommonWidgets.buildConditionChip(
                      context,
                      'オンライン購入',
                      _tempOnline ? 'yes' : 'unknown',
                      constrainText: true,
                      onTap: () => setState(() => _tempOnline = !_tempOnline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CommonWidgets.buildConditionChip(
                      context,
                      '洋酒',
                      _tempAlcohol ? 'yes' : 'unknown',
                      constrainText: true,
                      onTap: () => setState(() => _tempAlcohol = !_tempAlcohol),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

}

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final NumberFormat currencyFormat = NumberFormat('#,###');
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Navigator.of(context).pop(true);
        }
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: supabase.from('item').select().eq('item_id', widget.itemId).single(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: AppColors.greyLight,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Scaffold(
              backgroundColor: AppColors.greyLight,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
              body: const Center(child: Text('商品が見つかりません')),
            );
          }

          final item = snapshot.data!;

          return Scaffold(
            backgroundColor: AppColors.greyLight,
            appBar: AppBar(
              elevation: 0,
              shadowColor: AppColors.shadowColor,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              title: Text(
                item['item_name'] as String? ?? '',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSectionAsync(item),
                  _buildContentSection(item),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSectionAsync(Map<String, dynamic> item) {
    final ownImages = ItemImageService.ownImageUrls(item);
    if (ownImages.isNotEmpty) return _buildImageSection(item, ownImages);
    return FutureBuilder<List<String>>(
      future: ItemImageService.resolveImageUrls(item),
      builder: (context, snapshot) {
        return _buildImageSection(item, snapshot.data ?? []);
      },
    );
  }

  Widget _buildImageSection(Map<String, dynamic> item, List<String> imageUrls) {
    final imageCount = imageUrls.length;

    if (imageUrls.isEmpty) {
      return CategoryPlaceholder(
        category: item['item_category'] as String?,
        height: 300,
      );
    }

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // メイン画像にGestureDetectorを追加
          GestureDetector(
            onTap: () {}, // タップ処理は無効
            onPanUpdate: (details) {
              // 水平方向のスワイプ検出
              if (details.delta.dx > 10) {
                // 右スワイプ（前の画像へ）
                if (_currentImageIndex > 0) {
                  final newIndex = _currentImageIndex - 1;
                  setState(() {
                    _currentImageIndex = newIndex;
                  });
                  _pageController.animateToPage(
                    newIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              } else if (details.delta.dx < -10) {
                // 左スワイプ（次の画像へ）
                if (_currentImageIndex < imageCount - 1) {
                  final newIndex = _currentImageIndex + 1;
                  setState(() {
                    _currentImageIndex = newIndex;
                  });
                  _pageController.animateToPage(
                    newIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  // PageView
                  PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: imageCount,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.greyLight,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          print('Image loading error for URL: $url');
                          print('Error details: $error');
                          return Container(
                            color: AppColors.greyLight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: AppColors.errorColor,
                                ),
                                Text(
                                  'Error: $error',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // 左矢印ボタン（複数画像がある場合のみ）
                  if (imageCount > 1 && _currentImageIndex > 0)
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            final newIndex = _currentImageIndex - 1;
                            setState(() {
                              _currentImageIndex = newIndex;
                            });
                            _pageController.animateToPage(
                              newIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.blackLight.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.blackLight.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 右矢印ボタン（複数画像がある場合のみ）
                  if (imageCount > 1 && _currentImageIndex < imageCount - 1)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            final newIndex = _currentImageIndex + 1;
                            setState(() {
                              _currentImageIndex = newIndex;
                            });
                            _pageController.animateToPage(
                              newIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.blackLight.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.blackLight.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // オーバーレイサムネイル画像（複数画像がある場合のみ表示）
          if (imageCount > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blackDark.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < imageCount; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentImageIndex = i;
                          });
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: EdgeInsets.only(
                              right: i < imageCount - 1 ? 4 : 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _currentImageIndex == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              width: _currentImageIndex == i ? 2.5 : 2,
                            ),
                            boxShadow: _currentImageIndex == i
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: imageUrls[i],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.greyLight.withValues(alpha: 0.8),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.greyLight.withValues(alpha: 0.8),
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 12,
                                    color: AppColors.errorColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 画像インジケーター（複数画像がある場合のみ表示）
          if (imageCount > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blackDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / $imageCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item['item_name'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackDark,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 1.2,
                  child: FavoriteButton(
                    itemId: widget.itemId,
                    onFavoriteChanged: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBrandSection(item),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '価格',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.blackLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.currency_yen,
                            size: 20,
                            color: AppColors.blackDark,
                          ),
                          Text(
                            currencyFormat
                                .format(item['item_price'] as num? ?? 0),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '（税込）',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.blackLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
/*                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '評価',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.blackLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildStarRating(
                              context, item['item_rating'] as num? ?? 0),
                          const SizedBox(width: 4),
                          Text(
                            (item['item_rating'] as num?)?.toStringAsFixed(1) ??
                                'new',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ), */
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildProductDetails(item),
            _buildExternalLinkButton(item),
            _buildSameBrandProducts(item),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(Map<String, dynamic> item) {
    List<Widget> details = [];
    final expiryDate = item['item_expirydate'];
    if (expiryDate != null && expiryDate is num && expiryDate > 0) {
      details.add(_buildDetailItem('賞味期限', '${expiryDate.toInt()}日'));
    }
    final flags = <String, String>{
      'item_individualwrapping': '個包装',
      'item_roomtemperature': '常温',
      'item_online': 'オンライン購入',
      'item_alcohol': '洋酒',
    };

    final flagEntries = <MapEntry<String, String>>[];
    flags.forEach((itemKey, condKey) {
      final value = item[itemKey];
      final state = (value == true || value == 'yes' || value == '1' || value == 1)
          ? 'yes'
          : (value == false || value == 'no')
              ? 'no'
              : 'unknown';
      if (state != 'unknown') flagEntries.add(MapEntry(condKey, state));
    });

    if (flagEntries.isNotEmpty) {
      final rows = <Widget>[];
      for (int i = 0; i < flagEntries.length; i += 2) {
        rows.add(Row(
          children: [
            Expanded(child: _buildFlagChip(context, flagEntries[i].key, flagEntries[i].value)),
            if (i + 1 < flagEntries.length) ...[
              const SizedBox(width: 8),
              Expanded(child: _buildFlagChip(context, flagEntries[i + 1].key, flagEntries[i + 1].value)),
            ] else
              const Expanded(child: SizedBox()),
          ],
        ));
        if (i + 2 < flagEntries.length) rows.add(const SizedBox(height: 8));
      }
      details.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const SizedBox(height: 8), ...rows],
      ));
    }
    if (item['item_description'] != null &&
        (item['item_description'] as String).isNotEmpty) {
      if (details.isNotEmpty) {
        details.add(const SizedBox(height: 16));
      }
      details.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '商品説明',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.blackLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['item_description'] as String? ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.blackDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...details,
              const SizedBox(height: 16),
              Text(
                '※情報は正確ではない場合がございます。必ず公式サイトや店舗にてご確認ください。',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.blackLight.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.blackLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.blackDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlagChip(BuildContext context, String condKey, String state) {
    return CommonWidgets.buildConditionChip(context, condKey, state, constrainText: true);
  }

  Widget _buildExternalLinkButton(Map<String, dynamic> item) {
    final url = item['item_url'] as String?;
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '外部サイト',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackDark,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _launchURL(url),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.blackDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: AppColors.blackDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          url.length > 40 ? '${url.substring(0, 40)}...' : url,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.blackDark,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // URLを開くメソッド
  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 外部ブラウザで開く
        );
      } else {
        // URLを開けない場合の処理
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('このリンクを開くことができません'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      // エラーハンドリング
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('リンクを開けませんでした'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildBrandSection(Map<String, dynamic> item) {
    final brandId = item['brand_id']?.toString();

    if (brandId == null) {
      return Row(
        children: [
          const Icon(
            Icons.storefront,
            size: 18,
            color: AppColors.blackLight,
          ),
          const SizedBox(width: 6),
          Text(
            item['brand_name'] as String? ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.blackLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('brand').select().eq('brand_id', brandId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final brandData = snapshot.data!.first;
          final category = item['item_category'] as String?;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.storefront,
                    size: 18,
                    color: AppColors.blackLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    brandData['brand_name'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.blackLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (category != null && category.isNotEmpty) ...[  
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.greyMedium),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.blackLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          );
        }
        return Row(
          children: [
            const Icon(
              Icons.storefront,
              size: 18,
              color: AppColors.blackLight,
            ),
            const SizedBox(width: 6),
            const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  Widget _buildSameBrandProducts(Map<String, dynamic> item) {
    final brandId = item['brand_id']?.toString();

    if (brandId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          '同じブランドの商品',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.blackDark,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase
              .from('item')
              .select()
              .eq('brand_id', brandId)
              .limit(10),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final sameBrandItems = snapshot.data!
                .where((doc) => doc['item_id']?.toString() != widget.itemId)
                .toList();

            if (sameBrandItems.isEmpty) {
              return const Text(
                'ありません',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.blackLight,
                ),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sameBrandItems.length,
                itemBuilder: (context, index) {
                  final doc = sameBrandItems[index];
                  final itemData = doc;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ItemDetailScreen(itemId: itemData['item_id']),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.greyMedium),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greyMedium.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              child: _buildSameBrandItemImage(context, itemData),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemData['item_name'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.blackDark,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '¥${NumberFormat('#,###').format(itemData['item_price'] as num? ?? 0)}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.blackLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSameBrandItemImage(BuildContext context, Map<String, dynamic> itemData) {
    final ownImages = ItemImageService.ownImageUrls(itemData);
    if (ownImages.isNotEmpty) {
      return _buildSameBrandCachedImage(ownImages.first);
    }
    return FutureBuilder<List<String>>(
      future: ItemImageService.resolveImageUrls(itemData),
      builder: (context, snapshot) {
        final imageUrls = snapshot.data ?? [];
        if (imageUrls.isEmpty) {
          return CategoryPlaceholder(
            category: itemData['item_category'] as String?,
            height: double.infinity,
          );
        }
        return _buildSameBrandCachedImage(imageUrls.first);
      },
    );
  }

  Widget _buildSameBrandCachedImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: AppColors.greyLight,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.greyLight,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 20,
            color: AppColors.greyDark,
          ),
        ),
      ),
    );
  }
}

class FavoriteButton extends StatefulWidget {
  final String itemId;
  final VoidCallback onFavoriteChanged;

  const FavoriteButton({
    super.key,
    required this.itemId,
    required this.onFavoriteChanged,
  });

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late Future<bool> _isFavoriteFuture;

  @override
  void initState() {
    super.initState();
    _isFavoriteFuture = _checkFavoriteStatus();
  }

  Future<bool> _checkFavoriteStatus() async {
    return FavoriteService.instance.isFavorite(widget.itemId);
  }

  Future<void> _toggleFavorite() async {
    await FavoriteService.instance.toggle(widget.itemId);
    setState(() {
      _isFavoriteFuture = _checkFavoriteStatus();
    });
    widget.onFavoriteChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isFavoriteFuture,
      builder: (context, snapshot) {
        bool isFavorite = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppColors.favoriteColor : AppColors.greyDark,
            size: 22,
          ),
          onPressed: _toggleFavorite,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      },
    );
  }
}

