import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:alamode_app/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

Widget buildStarRating(BuildContext context, num rating) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      return Icon(
        Icons.star_rounded,
        color: index < rating
            ? AppColors.starColor
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      );
    }),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _tabs = [
    'all',
    'クッキー',
    'ショコラ',
    '和菓子',
    '焼き菓子',
    'ゼリー・プリン',
    '抹茶・ほうじ茶',
    'その他'
  ];
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showLeftArrow = false;
  bool _showRightArrow = true; // 初期状態では右矢印を表示

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
        // タブが変更されたときにスクロール位置を調整
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final tabWidth = 80.0; // おおよそのタブ幅
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
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 35.0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.0),
          child: _buildTabBarWithArrow(context),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((String name) => ItemList(key: ValueKey(name), genre: name))
            .toList(),
      ),
    );
  }

  Widget _buildTabBarWithArrow(BuildContext context) {
    return SizedBox(
      height: 32.0,
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
        height: 29.0,
        padding: EdgeInsets.symmetric(horizontal: isAllTab ? 15.0 : 10.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: isAllTab ? 0.0 : 2.0,
            bottom: 3.0, // 下の余白を統一
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: isAllTab ? 16.0 : 14.0, // 'all'のみ大きく
              fontWeight: FontWeight.normal,
              color: isSelected
                  ? AppColors.primaryColor
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
            color: AppColors.blackLight.withOpacity(0.7),
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

class ItemList extends StatefulWidget {
  final String genre;
  const ItemList({super.key, required this.genre});

  @override
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemList>
    with AutomaticKeepAliveClientMixin {
  List<DocumentSnapshot>? _cachedDocs;
  final currencyFormat = NumberFormat('#,###');
  String _sortBy = 'item_rating';
  static Map<String, bool> _globalFilterGenre = {};
  static double _globalFilterPriceMin = 0;
  static double _globalFilterPriceMax = 20000;
/*  static double _globalFilterRatingMin = 1;
  static double _globalFilterRatingMax = 5;
*/
  @override
  bool get wantKeepAlive => true;

// ローカル変数をglobal変数で初期化
  Map<String, bool> get _filterGenre => _globalFilterGenre;
  set _filterGenre(Map<String, bool> value) => _globalFilterGenre = value;

  double get _filterPriceMin => _globalFilterPriceMin;
  set _filterPriceMin(double value) => _globalFilterPriceMin = value;

  double get _filterPriceMax => _globalFilterPriceMax;
  set _filterPriceMax(double value) => _globalFilterPriceMax = value;

/*  double get _filterRatingMin => _globalFilterRatingMin;
  set _filterRatingMin(double value) => _globalFilterRatingMin = value;

  double get _filterRatingMax => _globalFilterRatingMax;
  set _filterRatingMax(double value) => _globalFilterRatingMax = value;
*/

// 並び替えオプション
  static const List<Map<String, String>> _sortOptions = [
/*    {'value': 'item_rating', 'label': '評価が高い順'},*/
    {'value': 'item_price_low', 'label': '価格の安い順'},
    {'value': 'item_price_high', 'label': '価格の高い順'},
    {'value': 'item_brand', 'label': 'ブランド名順'},
  ];

// ソートフィールドを取得
  String get _sortField =>
      _sortBy.startsWith('item_price') ? 'item_price' : _sortBy;

  bool get _sortDescending {
    switch (_sortBy) {
/*      case 'item_rating': */
      case 'item_price_high':
        return true; // 降順
      case 'item_brand':
      case 'item_price_low':
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
                ? StreamBuilder<QuerySnapshot>(
                    stream: _getFilteredQuery().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('エラーが発生しました'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('coming soon'));
                      }

                      _cachedDocs = snapshot.data!.docs;
                      return _buildItemList(_cachedDocs!);
                    },
                  )
                : _buildItemList(_cachedDocs!),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _cachedDocs = null; // キャッシュをクリア
    });

    await Future.delayed(const Duration(milliseconds: 500)); // ローディング表示
  }

  Widget _buildItemList(List<DocumentSnapshot> docs) {
    List<DocumentSnapshot> filteredDocs = _applyClientSideFilters(docs);

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
        final document = filteredDocs[itemIndex];
        final item = document.data() as Map<String, dynamic>?;
        if (item == null) {
          return const SizedBox.shrink();
        }
        return _buildItemCard(context, document, item, itemIndex);
      },
    );
  }

  List<DocumentSnapshot> _applyClientSideFilters(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      final item = doc.data() as Map<String, dynamic>?;
      if (item == null) return false;

      // 価格フィルター
      final price = (item['item_price'] as num?)?.toDouble() ?? 0;
      if (price < _filterPriceMin || price > _filterPriceMax) {
        return false;
      }

/*      // 評価フィルター
      final rating = (item['item_rating'] as num?)?.toDouble() ?? 0;
      if (rating < _filterRatingMin || rating > _filterRatingMax) {
        return false;
      }
*/
      return true;
    }).toList();
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
            // 新しくRowでラップして間隔調整
            children: [
              IconButton(
                icon: const Icon(
                  Icons.filter_list_alt,
                  color: AppColors.blackLight,
                ),
                tooltip: 'フィルタリング',
                onPressed: _openFilterDialog,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
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
                              ? AppColors.secondryColor
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
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    final hasGenreFilter = _filterGenre.values.any((selected) => selected);
    final hasPriceFilter = _filterPriceMin > 0 || _filterPriceMax < 20000;
/*    final hasRatingFilter = _filterRatingMin > 1 || _filterRatingMax < 5; */
    return hasGenreFilter || hasPriceFilter /*|| hasRatingFilter */;
  }

  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    // ジャンルフィルター（allタブの時のみ表示）
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

  Query _getFilteredQuery() {
    Query baseQuery = widget.genre == 'all'
        ? FirebaseFirestore.instance.collection('item')
        : FirebaseFirestore.instance
            .collection('item')
            .where('item_genre', isEqualTo: widget.genre);

    // ジャンルフィルタリング（allタブでのみ適用）
    if (_filterGenre.isNotEmpty && widget.genre == 'all') {
      final selectedGenres = _filterGenre.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      if (selectedGenres.isNotEmpty) {
        baseQuery = baseQuery.where('item_genre', whereIn: selectedGenres);
      }
    }

    return baseQuery.orderBy(_sortField, descending: _sortDescending);
  }

  Future<void> _openFilterDialog() async {
    // Firestoreからアイテムデータを取得してフィルタダイアログに渡す
    final snapshot = await FirebaseFirestore.instance.collection('item').get();
    final itemList = snapshot.docs.map((doc) => doc.data()).toList();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => HomeFilterDialog(
        itemList: itemList,
        currentFilterGenre: _filterGenre, // 常に現在のフィルター状態を渡す
        currentPriceMin: _filterPriceMin,
        currentPriceMax: _filterPriceMax,
/*        currentFilterRatingMin: _filterRatingMin,
        currentFilterRatingMax: _filterRatingMax, */
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
/*        _filterRatingMin = result['filterRatingMin'];
        _filterRatingMax = result['filterRatingMax']; */
        _cachedDocs = null;
      });
    }
  }

  Widget _buildItemCard(BuildContext context, DocumentSnapshot document,
      Map<String, dynamic> item, int index) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(itemId: document.id),
          ),
        );
        if (result == true) setState(() {});
      },
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
              color: AppColors.greyMedium.withOpacity(0.8),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemHeader(item, document.id),
            _buildItemImages(item['item_imageurl'] as String? ?? ''),
            _buildItemFooter(item),
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader(Map<String, dynamic> item, String itemId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['item_name'] as String? ?? '',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.storefront, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    item['item_brand'] as String? ?? '',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(width: 25),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.greyDark, width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item['item_genre'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.blackLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
          Positioned(
            right: 0,
            top: 10,
            child: Transform.scale(
              scale: 1.2,
              child: FavoriteButton(
                itemId: itemId,
                onFavoriteChanged: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImages(String imageUrl) {
    return Row(
      children: [
        for (int i = 0; i < 3; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 1 : 0),
              height: 110,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.errorColor,
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

  Widget _buildItemFooter(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
/*          buildStarRating(context, item['item_rating'] as num? ?? 0),
          const SizedBox(width: 4),
          Text(
            (item['item_rating'] as num?)?.toStringAsFixed(1) ?? 'new',
            style: const TextStyle(fontSize: 14),
          ),
		*/
          const Spacer(),
          const Icon(Icons.currency_yen, size: 18),
          const SizedBox(width: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(item['item_price'] as num? ?? 0),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 2),
              const Text(
                '（税込）',
                style: TextStyle(fontSize: 10, color: AppColors.blackLight),
              ),
            ],
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
/*  final double currentFilterRatingMin;
  final double currentFilterRatingMax; */
  final bool isAllTab;

  const HomeFilterDialog({
    super.key,
    required this.itemList,
    required this.currentFilterGenre,
    required this.currentPriceMin,
    required this.currentPriceMax,
/*    required this.currentFilterRatingMin,
    required this.currentFilterRatingMax, */
    required this.isAllTab,
  });

  @override
  State<HomeFilterDialog> createState() => _HomeFilterDialogState();
}

class _HomeFilterDialogState extends State<HomeFilterDialog> {
  late Map<String, bool> _tempFilterGenre;
  late RangeValues _tempFilterPriceRange;
/*  late RangeValues _tempFilterRatingRange; */

  @override
  void initState() {
    super.initState();
    _tempFilterGenre = Map.from(widget.currentFilterGenre);
    _tempFilterPriceRange =
        RangeValues(widget.currentPriceMin, widget.currentPriceMax);
/*    _tempFilterRatingRange = RangeValues(
        widget.currentFilterRatingMin, widget.currentFilterRatingMax); */
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
              color: AppColors.blackDark.withOpacity(0.15),
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
                  const Text(
                    'フィルタリング',
                    style: TextStyle(
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
                    // ジャンルフィルター（allタブの時のみ表示）
                    if (widget.isAllTab) ...[
                      _buildGenreFilter(),
                      const SizedBox(height: 24),
                    ],
                    _buildPriceFilter(),
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
                    color: AppColors.primaryColor,
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
/*                          'filterRatingMin': _tempFilterRatingRange.start,
                          'filterRatingMax': _tempFilterRatingRange.end, */
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
    const genres = ['クッキー', 'ショコラ', '和菓子', '焼き菓子', 'ゼリー・プリン', '抹茶・ほうじ茶', 'その他'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ジャンル',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.greyLight,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.blackDark
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

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '金額範囲',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
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
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: Text(
                      _tempFilterPriceRange.start == 0
                          ? '指定しない'
                          : '¥${NumberFormat('#,###').format(_tempFilterPriceRange.start.toInt())}',
                      style: const TextStyle(
                        color: AppColors.blackDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    '〜',
                    style: TextStyle(color: AppColors.blackDark, fontSize: 16),
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
                        color: AppColors.blackDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primaryColor,
                  thumbColor: AppColors.primaryColor,
                  overlayColor: AppColors.primaryColor.withOpacity(0.2),
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

/*  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '評価',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
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
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(
                          _tempFilterRatingRange.start.toInt(),
                          (index) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.starColor,
                            size: 16,
                          ),
                        ),
                        if (_tempFilterRatingRange.start < 5)
                          ...List.generate(
                            5 - _tempFilterRatingRange.start.toInt(),
                            (index) => Icon(
                              Icons.star_rounded,
                              color: AppColors.greyDark.withOpacity(0.3),
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Text(
                    '〜',
                    style: TextStyle(color: AppColors.blackDark, fontSize: 16),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyMedium),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(
                          _tempFilterRatingRange.end.toInt(),
                          (index) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.starColor,
                            size: 16,
                          ),
                        ),
                        if (_tempFilterRatingRange.end < 5)
                          ...List.generate(
                            5 - _tempFilterRatingRange.end.toInt(),
                            (index) => Icon(
                              Icons.star_rounded,
                              color: AppColors.greyDark.withOpacity(0.3),
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primaryColor,
                  thumbColor: AppColors.primaryColor,
                  overlayColor: AppColors.primaryColor.withOpacity(0.2),
                  inactiveTrackColor: AppColors.greyLight,
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: RangeSlider(
                  min: 1,
                  max: 5,
                  divisions: 4,
                  values: _tempFilterRatingRange,
                  onChanged: (values) =>
                      setState(() => _tempFilterRatingRange = values),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }*/
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        backgroundColor: AppColors.greyLight,
        appBar: AppBar(
          elevation: 0,
          shadowColor: AppColors.shadowColor,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('item')
                .doc(widget.itemId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('');
              final item = snapshot.data!.data() as Map<String, dynamic>?;
              return Text(
                item?['item_name'] as String? ?? '',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('item')
              .doc(widget.itemId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'エラーが発生しました',
                  style: TextStyle(color: AppColors.errorColor),
                ),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  '商品が見つかりません',
                  style: TextStyle(color: AppColors.blackLight),
                ),
              );
            }
            final item = snapshot.data!.data() as Map<String, dynamic>?;
            if (item == null) {
              return const Center(
                child: Text(
                  '商品データが見つかりません',
                  style: TextStyle(color: AppColors.blackLight),
                ),
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(item),
                  _buildContentSection(item),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSection(Map<String, dynamic> item) {
    final imageUrl = item['item_imageurl'] as String? ?? '';

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // メイン画像
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              children: [
                // PageView
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.greyLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.greyLight,
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 60,
                            color: AppColors.errorColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 左矢印ボタン
                if (_currentImageIndex > 0)
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
                            color: AppColors.blackLight.withOpacity(0.5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blackLight.withOpacity(0.2),
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

                // 右矢印ボタン
                if (_currentImageIndex < 2)
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
                            color: AppColors.blackLight.withOpacity(0.5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blackLight.withOpacity(0.2),
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

          // オーバーレイサムネイル画像（下部に重ねて表示）
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackDark.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 3; i++)
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
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _currentImageIndex == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            width: _currentImageIndex == i ? 2.5 : 2,
                          ),
                          boxShadow: _currentImageIndex == i
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.greyLight.withOpacity(0.8),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.greyLight.withOpacity(0.8),
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

          // 画像インジケーター（右上）
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blackDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1} / 3',
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
            Row(
              children: [
                const Icon(
                  Icons.storefront,
                  size: 18,
                  color: AppColors.blackLight,
                ),
                const SizedBox(width: 6),
                Text(
                  item['item_brand'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.blackLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGenreSection(item),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGenreSection(Map<String, dynamic> item) {
    final genreString = item['item_genre'] as String? ?? '';
    if (genreString.isEmpty) return const SizedBox.shrink();

    final genres = genreString.split(',').map((e) => e.trim()).toList();

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.greyMedium),
          ),
          child: Text(
            genre,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.blackLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
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
    };

    List<Widget> flagWidgets = [];
    flags.forEach((key, label) {
      final value = item[key];
      if (value != null) {
        final isActive = value == "1" || value == 1;
        flagWidgets.add(_buildFlagChip(label, isActive));
      }
    });

    if (flagWidgets.isNotEmpty) {
      details.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: flagWidgets,
            ),
          ],
        ),
      );
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
                  color: AppColors.blackLight.withOpacity(0.8),
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

  Widget _buildFlagChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : AppColors.greyMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primaryColor : AppColors.blackLight,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? AppColors.primaryColor : AppColors.blackLight,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildExternalLinkButton(Map<String, dynamic> item) {
    final url = item['item_URL'] as String?;
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
// ローカルストレージから状態を取得
    final prefs = await SharedPreferences.getInstance();
    final favorite = prefs.getStringList('favorite') ?? [];
    return favorite.contains(widget.itemId);
  }

  Future<void> _toggleFavorite() async {
// ローカルストレージで処理
    await _toggleFavoriteInLocalStorage();
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        bool isFavorite = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppColors.favoriteColor : AppColors.greyDark,
            size: 22,
          ),
          onPressed: _toggleFavorite,
        );
      },
    );
  }

  Future<void> _toggleFavoriteInLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final favorite = prefs.getStringList('favorite') ?? [];
    if (favorite.contains(widget.itemId)) {
      favorite.remove(widget.itemId);
    } else {
      favorite.add(widget.itemId);
    }
    await prefs.setStringList('favorite', favorite);
  }
}

// 共通の広告関連ユーティリティ関数
class AdUtils {
// リスト全体のアイテム数を計算（広告も含む）
  static int calculateListItemCount(int itemCount) {
    if (itemCount <= 3) return itemCount;
    return itemCount + ((itemCount - 1) ~/ 3); // 3件ごとに広告を1つ追加
  }

// 指定されたインデックスで広告を表示するかチェック
  static bool shouldShowAdAt(int index) {
    return index > 0 && (index + 1) % 4 == 0; // 4, 8, 12... の位置で広告表示
  }

// 広告によるオフセットを考慮した実際のアイテムインデックスを取得
  static int getActualItemIndex(int listIndex) {
    final adCount = (listIndex) ~/ 4; // この位置より前にある広告の数
    return listIndex - adCount;
  }

// 広告バナーを作成
  static Widget buildAdBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.greyMedium.withOpacity(0.8),
        border: Border.all(color: AppColors.greyMedium, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyMedium.withOpacity(0.8),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 広告コンテンツエリア
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.greyLight,
                  AppColors.greyMedium,
                ],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ads_click,
                    color: AppColors.blackLight,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'スポンサード',
                    style: TextStyle(
                      color: AppColors.blackLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 右上の「広告」ラベル
          Positioned(
            top: 6,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.greyDark,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '広告',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
