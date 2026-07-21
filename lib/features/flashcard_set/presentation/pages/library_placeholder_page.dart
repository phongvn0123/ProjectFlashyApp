import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'favorite_flashcard_sets_page.dart';
import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import 'flashcard_set_detail_page.dart';
import 'create_flashcard_set_page.dart';

enum LibraryFilter {
  all,
  mine,
  favorite,
}

class LibraryPlaceholderPage extends ConsumerStatefulWidget {
  const LibraryPlaceholderPage({super.key});

  @override
  ConsumerState<LibraryPlaceholderPage> createState() =>
      _LibraryPlaceholderPageState();
}

class _LibraryPlaceholderPageState
    extends ConsumerState<LibraryPlaceholderPage> {
  final TextEditingController _searchController = TextEditingController();

  LibraryFilter _selectedFilter = LibraryFilter.all;

  // Tạm thời lưu yêu thích trong bộ nhớ.
  // Bước sau chúng ta sẽ lưu xuống SQLite.
  //final Set<String> _favoriteSetIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeFilter(LibraryFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  // void _toggleFavorite(String setId) {
  //   setState(() {
  //     if (_favoriteSetIds.contains(setId)) {
  //       _favoriteSetIds.remove(setId);
  //     } else {
  //       _favoriteSetIds.add(setId);
  //     }
  //   });
  // }

  List<FlashcardSet> _applyFilter({
    required List<FlashcardSet> sets,
    required String? currentUserId,
    required Set<String> favoriteSetIds,
  }) {
    switch (_selectedFilter) {
      case LibraryFilter.all:
        return sets.where((set) {
          return set.visibility == 'public' ||
              set.ownerId == currentUserId;
        }).toList();

      case LibraryFilter.mine:
        if (currentUserId == null) {
          return [];
        }

        return sets
            .where((set) => set.ownerId == currentUserId)
            .toList();

      case LibraryFilter.favorite:
        if (currentUserId == null) {
          return [];
        }

        return sets.where((set) {
          final canView = set.visibility == 'public' ||
              set.ownerId == currentUserId;

          return canView && favoriteSetIds.contains(set.id);
        }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final favoriteIdsAsync = user == null
        ? const AsyncData<Set<String>>(<String>{})
        : ref.watch(favoriteSetIdsProvider(user.id));

    final favoriteSetIds =
        favoriteIdsAsync.asData?.value ?? <String>{};
    final setsAsync = ref.watch(
      setsProvider(_searchController.text.trim()),
    );
    if (favoriteIdsAsync.isLoading && user != null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(setsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildSearchField(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _buildFilters(),
                ),
              ),
              setsAsync.when(
                loading: () {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                error: (error, stackTrace) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Không thể tải danh sách bộ thẻ.\n$error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
                data: (sets) {
                  final filteredSets = _applyFilter(
                    sets: sets,
                    currentUserId: user?.id,
                    favoriteSetIds: favoriteSetIds,
                  );

                  if (filteredSets.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: filteredSets.length + 1,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 12);
                      },
                      itemBuilder: (context, index) {
                        if (index == filteredSets.length) {
                          return _buildExploreCard();
                        }

                        final set = filteredSets[index];

                        return _FlashcardSetCard(
                          set: set,
                          isFavorite: favoriteSetIds.contains(set.id),
                          onFavoritePressed: () async {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bạn cần đăng nhập để yêu thích bộ thẻ'),
                                ),
                              );
                              return;
                            }

                            try {
                              final isFavorite = await ref
                                  .read(repositoryProvider)
                                  .toggleSetFavorite(
                                userId: user.id,
                                setId: set.id,
                              );

                              await ref.refresh(
                                favoriteSetIdsProvider(user.id).future,
                              );

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavorite
                                        ? 'Đã thêm vào yêu thích'
                                        : 'Đã bỏ khỏi yêu thích',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            } catch (error, stackTrace) {
                              debugPrint('Lỗi toggle favorite: $error');
                              debugPrintStack(stackTrace: stackTrace);

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Không thể cập nhật yêu thích: $error'),
                                ),
                              );
                            }
                          },
                          onPressed: () async {                            final deleted = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => FlashcardSetDetailPage(
                                  setId: set.id,
                                ),
                              ),
                            );

                            if (deleted == true) {
                              ref.invalidate(setsProvider);

                              if (user != null) {
                                ref.invalidate(favoriteSetIdsProvider(user.id));
                              }
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Thư viện',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF202124),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () async {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const CreateFlashcardSetPage(),
              ),
            );

            if (created == true) {
              ref.invalidate(setsProvider);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF3C4043),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          icon: const Icon(
            Icons.add,
            size: 18,
          ),
          label: const Text(
            'Tạo',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Tìm bộ thẻ...',
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
          icon: const Icon(Icons.close),
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

  Widget _buildFilters() {
    return Row(
      children: [
        _LibraryFilterButton(
          label: 'Tất cả',
          selected: _selectedFilter == LibraryFilter.all,
          onPressed: () {
            _changeFilter(LibraryFilter.all);
          },
        ),
        const SizedBox(width: 8),
        _LibraryFilterButton(
          label: 'Của tôi',
          selected: _selectedFilter == LibraryFilter.mine,
          onPressed: () {
            _changeFilter(LibraryFilter.mine);
          },
        ),
        const SizedBox(width: 8),
        _LibraryFilterButton(
          label: 'Yêu thích',
          selected: false,
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                const FavoriteFlashcardSetsPage(),
              ),
            );

            if (!mounted) return;

            final user =
                ref.read(authControllerProvider).asData?.value;

            ref.invalidate(setsProvider);

            if (user != null) {
              ref.invalidate(
                favoriteSetIdsProvider(user.id),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String title;
    String description;
    IconData icon;

    switch (_selectedFilter) {
      case LibraryFilter.all:
        title = 'Chưa có bộ thẻ';
        description = 'Hãy tạo bộ thẻ đầu tiên để bắt đầu học.';
        icon = Icons.style_outlined;

      case LibraryFilter.mine:
        title = 'Bạn chưa có bộ thẻ';
        description = 'Nhấn nút Tạo để tạo bộ thẻ của riêng bạn.';
        icon = Icons.create_new_folder_outlined;

      case LibraryFilter.favorite:
        title = 'Chưa có bộ thẻ yêu thích';
        description =
        'Nhấn biểu tượng trái tim để thêm bộ thẻ vào danh sách yêu thích.';
        icon = Icons.favorite_border;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 70,
              color: const Color(0xFFD5D9E2),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCard() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.school_outlined,
            size: 38,
            color: Color(0xFF9AA7BF),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mở rộng kiến thức của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Khám phá hàng ngàn bộ thẻ được chia sẻ bởi cộng đồng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B67D1),
              side: const BorderSide(
                color: Color(0xFF0B67D1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text('Khám phá ngay'),
          ),
        ],
      ),
    );
  }
}

class _LibraryFilterButton extends StatelessWidget {
  const _LibraryFilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF0B67D1)
          : const Color(0xFFF0F2F8),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : const Color(0xFF5F6368),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashcardSetCard extends StatelessWidget {
  const _FlashcardSetCard({
    required this.set,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onPressed,
  });

  final FlashcardSet set;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isPublic = set.visibility == 'public';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPublic ? 'Công khai' : 'Riêng tư',
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
                    Text(
                      '${set.cardCount} thẻ ghi nhớ',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                    if (set.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        set.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9AA0A6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavoritePressed,
                tooltip: isFavorite
                    ? 'Bỏ khỏi yêu thích'
                    : 'Thêm vào yêu thích',
                icon: Icon(
                  isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: isFavorite
                      ? const Color(0xFF0B67D1)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}