import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import 'flashcard_set_detail_page.dart';

enum FavoriteSetSort {
  titleAscending,
  titleDescending,
  mostCards,
  leastCards,
}

class FavoriteFlashcardSetsPage extends ConsumerStatefulWidget {
  const FavoriteFlashcardSetsPage({
    super.key,
  });

  @override
  ConsumerState<FavoriteFlashcardSetsPage> createState() =>
      _FavoriteFlashcardSetsPageState();
}

class _FavoriteFlashcardSetsPageState
    extends ConsumerState<FavoriteFlashcardSetsPage> {
  final TextEditingController _searchController =
  TextEditingController();

  FavoriteSetSort _selectedSort =
      FavoriteSetSort.titleAscending;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _sortLabel {
    switch (_selectedSort) {
      case FavoriteSetSort.titleAscending:
        return 'Tên A → Z';

      case FavoriteSetSort.titleDescending:
        return 'Tên Z → A';

      case FavoriteSetSort.mostCards:
        return 'Nhiều thẻ nhất';

      case FavoriteSetSort.leastCards:
        return 'Ít thẻ nhất';
    }
  }

  List<FlashcardSet> _filterAndSortSets({
    required List<FlashcardSet> sets,
    required Set<String> favoriteSetIds,
    required String currentUserId,
  }) {
    final query = _searchController.text
        .trim()
        .toLowerCase();

    final favoriteSets = sets.where((set) {
      final isFavorite = favoriteSetIds.contains(set.id);

      final canView = set.visibility == 'public' ||
          set.ownerId == currentUserId;

      final matchesSearch =
          set.title.toLowerCase().contains(query) ||
              set.description.toLowerCase().contains(query);

      return isFavorite && canView && matchesSearch;
    }).toList();

    switch (_selectedSort) {
      case FavoriteSetSort.titleAscending:
        favoriteSets.sort(
              (first, second) => first.title
              .toLowerCase()
              .compareTo(second.title.toLowerCase()),
        );

      case FavoriteSetSort.titleDescending:
        favoriteSets.sort(
              (first, second) => second.title
              .toLowerCase()
              .compareTo(first.title.toLowerCase()),
        );

      case FavoriteSetSort.mostCards:
        favoriteSets.sort(
              (first, second) =>
              second.cardCount.compareTo(first.cardCount),
        );

      case FavoriteSetSort.leastCards:
        favoriteSets.sort(
              (first, second) =>
              first.cardCount.compareTo(second.cardCount),
        );
    }

    return favoriteSets;
  }

  Future<void> _showSortBottomSheet() async {
    final selectedSort =
    await showModalBottomSheet<FavoriteSetSort>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
              MediaQuery.of(bottomSheetContext).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        12,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sắp xếp bộ thẻ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    RadioListTile<FavoriteSetSort>(
                      value: FavoriteSetSort.titleAscending,
                      groupValue: _selectedSort,
                      title: const Text('Tên A → Z'),
                      secondary: const Icon(
                        Icons.sort_by_alpha,
                      ),
                      onChanged: (value) {
                        Navigator.of(bottomSheetContext).pop(value);
                      },
                    ),
                    RadioListTile<FavoriteSetSort>(
                      value: FavoriteSetSort.titleDescending,
                      groupValue: _selectedSort,
                      title: const Text('Tên Z → A'),
                      secondary: const Icon(
                        Icons.sort_by_alpha,
                      ),
                      onChanged: (value) {
                        Navigator.of(bottomSheetContext).pop(value);
                      },
                    ),
                    RadioListTile<FavoriteSetSort>(
                      value: FavoriteSetSort.mostCards,
                      groupValue: _selectedSort,
                      title: const Text('Nhiều thẻ nhất'),
                      secondary: const Icon(
                        Icons.arrow_downward_rounded,
                      ),
                      onChanged: (value) {
                        Navigator.of(bottomSheetContext).pop(value);
                      },
                    ),
                    RadioListTile<FavoriteSetSort>(
                      value: FavoriteSetSort.leastCards,
                      groupValue: _selectedSort,
                      title: const Text('Ít thẻ nhất'),
                      secondary: const Icon(
                        Icons.arrow_upward_rounded,
                      ),
                      onChanged: (value) {
                        Navigator.of(bottomSheetContext).pop(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selectedSort == null) return;

    setState(() {
      _selectedSort = selectedSort;
    });
  }

  Future<void> _removeFavorite({
    required String userId,
    required String setId,
  }) async {
    try {
      await ref.read(repositoryProvider).toggleSetFavorite(
        userId: userId,
        setId: setId,
      );

      ref.invalidate(
        favoriteSetIdsProvider(userId),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã bỏ bộ thẻ khỏi danh sách yêu thích.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể cập nhật yêu thích: $error',
          ),
        ),
      );
    }
  }

  Future<void> _refresh(String userId) async {
    ref.invalidate(setsProvider);
    ref.invalidate(
      favoriteSetIdsProvider(userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        ref.watch(authControllerProvider).asData?.value;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FF),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Bộ thẻ yêu thích',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Bạn cần đăng nhập để xem bộ thẻ yêu thích.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final favoriteIdsAsync = ref.watch(
      favoriteSetIdsProvider(user.id),
    );

    final setsAsync = ref.watch(
      setsProvider(''),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Bộ thẻ yêu thích',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: favoriteIdsAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return _ErrorState(
            message:
            'Không thể tải danh sách yêu thích.\n$error',
            onRetry: () {
              ref.invalidate(
                favoriteSetIdsProvider(user.id),
              );
            },
          );
        },
        data: (favoriteSetIds) {
          return setsAsync.when(
            loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            error: (error, stackTrace) {
              return _ErrorState(
                message:
                'Không thể tải danh sách bộ thẻ.\n$error',
                onRetry: () {
                  ref.invalidate(setsProvider);
                },
              );
            },
            data: (sets) {
              final favoriteSets = _filterAndSortSets(
                sets: sets,
                favoriteSetIds: favoriteSetIds,
                currentUserId: user.id,
              );

              final hasAnyFavorite =
                  favoriteSetIds.isNotEmpty;

              return RefreshIndicator(
                onRefresh: () => _refresh(user.id),
                child: CustomScrollView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _buildSearchField(),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        16,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${favoriteSets.length} bộ thẻ',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _showSortBottomSheet,
                              icon: const Icon(
                                Icons.sort_rounded,
                                size: 18,
                              ),
                              label: Text(_sortLabel),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                const Color(0xFF0B67D1),
                                side: const BorderSide(
                                  color: Color(0xFFD6E4F7),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (favoriteSets.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          isSearching:
                          _searchController.text.trim().isNotEmpty,
                          hasAnyFavorite: hasAnyFavorite,
                          onClearSearch: () {
                            _searchController.clear();

                            setState(() {});
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          30,
                        ),
                        sliver: SliverList.separated(
                          itemCount: favoriteSets.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            final set = favoriteSets[index];

                            return _FavoriteSetCard(
                              set: set,
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FlashcardSetDetailPage(
                                          setId: set.id,
                                        ),
                                  ),
                                );

                                if (!mounted) return;

                                ref.invalidate(setsProvider);
                                ref.invalidate(
                                  favoriteSetIdsProvider(
                                    user.id,
                                  ),
                                );
                              },
                              onRemoveFavorite: () {
                                _removeFavorite(
                                  userId: user.id,
                                  setId: set.id,
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Tìm theo tên hoặc mô tả...',
        hintStyle: const TextStyle(
          color: Color(0xFF9AA0A6),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF9AA0A6),
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
          onPressed: () {
            _searchController.clear();

            setState(() {});
          },
          tooltip: 'Xóa tìm kiếm',
          icon: const Icon(
            Icons.close,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF0F2F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF0B67D1),
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

class _FavoriteSetCard extends StatelessWidget {
  const _FavoriteSetCard({
    required this.set,
    required this.onPressed,
    required this.onRemoveFavorite,
  });

  final FlashcardSet set;
  final VoidCallback onPressed;
  final VoidCallback onRemoveFavorite;

  @override
  Widget build(BuildContext context) {
    final isPublic = set.visibility == 'public';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            10,
            14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPublic
                            ? const Color(0xFFEAF3FF)
                            : const Color(0xFFF1F3F4),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPublic
                            ? 'Công khai'
                            : 'Riêng tư',
                        style: TextStyle(
                          color: isPublic
                              ? const Color(0xFF0B67D1)
                              : const Color(0xFF5F6368),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      set.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.style_outlined,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${set.cardCount} thẻ ghi nhớ',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (set.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        set.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9AA0A6),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemoveFavorite,
                tooltip: 'Bỏ khỏi yêu thích',
                icon: const Icon(
                  Icons.favorite,
                  color: Color(0xFF0B67D1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSearching,
    required this.hasAnyFavorite,
    required this.onClearSearch,
  });

  final bool isSearching;
  final bool hasAnyFavorite;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final noSearchResult =
        isSearching && hasAnyFavorite;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          32,
          30,
          32,
          80,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noSearchResult
                  ? Icons.search_off_rounded
                  : Icons.favorite_border,
              size: 72,
              color: const Color(0xFFD5D9E2),
            ),
            const SizedBox(height: 18),
            Text(
              noSearchResult
                  ? 'Không tìm thấy bộ thẻ'
                  : 'Chưa có bộ thẻ yêu thích',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noSearchResult
                  ? 'Không có bộ thẻ yêu thích nào phù hợp với từ khóa của bạn.'
                  : 'Nhấn biểu tượng trái tim trong Thư viện để thêm bộ thẻ vào đây.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            if (noSearchResult) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.close),
                label: const Text('Xóa tìm kiếm'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 62,
              color: Color(0xFF9AA0A6),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}