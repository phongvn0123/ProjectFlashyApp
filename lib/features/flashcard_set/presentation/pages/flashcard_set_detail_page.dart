import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'create_flashcard_set_page.dart';
import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FlashcardSetDetailPage extends ConsumerStatefulWidget {
  const FlashcardSetDetailPage({
    super.key,
    required this.setId,
  });

  final String setId;

  @override
  ConsumerState<FlashcardSetDetailPage> createState() =>
      _FlashcardSetDetailPageState();
}

class _FlashcardSetDetailPageState
    extends ConsumerState<FlashcardSetDetailPage> {
  late final FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.45);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final value = text.trim();

    if (value.isEmpty) return;

    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak(value);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể phát âm: $error'),
        ),
      );
    }
  }

  Future<bool?> _confirmDelete(
      BuildContext context,
      String setTitle,
      ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa bộ thẻ?'),
          content: Text(
            'Bạn có chắc muốn xóa "$setTitle" không?\n\n'
                'Toàn bộ thẻ ghi nhớ trong bộ này cũng sẽ bị xóa.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;

    final setAsync = ref.watch(
      flashcardSetProvider(widget.setId),
    );

    final cardsAsync = ref.watch(
      cardsProvider(widget.setId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chi tiết bộ thẻ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: setAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Không thể tải bộ thẻ.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (set) {
          if (set == null) {
            return const Center(
              child: Text('Không tìm thấy bộ thẻ'),
            );
          }

          final isOwner = user?.id == set.ownerId;
          final isPublic = set.visibility == 'public';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                flashcardSetProvider(widget.setId),
              );
              ref.invalidate(
                cardsProvider(widget.setId),
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                30,
              ),
              children: [
                _SetInformationCard(
                  set: set,
                  isPublic: isPublic,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Màn học sẽ được kết nối ở bước sau',
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          backgroundColor: const Color(0xFF0B67D1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'Học ngay',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: cardsAsync.asData == null
                            ? null
                            : () async {
                          final updated =
                          await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateFlashcardSetPage(
                                    initialSet: set,
                                    initialCards:
                                    cardsAsync.asData!.value,
                                  ),
                            ),
                          );

                          if (updated == true) {
                            ref.invalidate(
                              flashcardSetProvider(
                                widget.setId,
                              ),
                            );
                            ref.invalidate(
                              cardsProvider(widget.setId),
                            );
                            ref.invalidate(setsProvider);
                          }
                        },
                        tooltip: 'Chỉnh sửa',
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () async {
                          final confirmed = await _confirmDelete(
                            context,
                            set.title,
                          );

                          if (confirmed != true) return;

                          try {
                            await ref
                                .read(repositoryProvider)
                                .deleteSet(set.id);

                            if (!context.mounted) return;

                            Navigator.of(context).pop(true);
                          } catch (error) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Không thể xóa bộ thẻ: $error',
                                ),
                              ),
                            );
                          }
                        },
                        tooltip: 'Xóa bộ thẻ',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Danh sách thẻ',
                  style:
                  Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                cardsAsync.when(
                  loading: () {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  error: (error, stackTrace) {
                    return _MessageCard(
                      icon: Icons.error_outline,
                      message:
                      'Không thể tải danh sách thẻ.\n$error',
                    );
                  },
                  data: (cards) {
                    if (cards.isEmpty) {
                      return const _MessageCard(
                        icon: Icons.style_outlined,
                        message: 'Bộ này chưa có thẻ ghi nhớ.',
                      );
                    }

                    return Column(
                      children: [
                        for (
                        int index = 0;
                        index < cards.length;
                        index++
                        ) ...[
                          _FlashcardItem(
                            card: cards[index],
                            index: index,
                            onSpeak: () {
                              _speak(cards[index].front);
                            },
                          ),
                          if (index != cards.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class _SetInformationCard extends StatelessWidget {
  const _SetInformationCard({
    required this.set,
    required this.isPublic,
  });

  final FlashcardSet set;
  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            set.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF202124),
            ),
          ),
          if (set.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              set.description,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.style_outlined,
                size: 20,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                '${set.cardCount} thẻ ghi nhớ',
                style: const TextStyle(
                  color: Color(0xFF5F6368),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlashcardItem extends StatelessWidget {
  const _FlashcardItem({
    required this.card,
    required this.index,
    required this.onSpeak,
  });

  final Flashcard card;
  final int index;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thẻ ${index + 1}',
            style: const TextStyle(
              color: Color(0xFF0B67D1),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mặt trước',
            style: TextStyle(
              color: Color(0xFF9AA0A6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  card.front,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202124),
                  ),
                ),
              ),
              IconButton(
                onPressed: onSpeak,
                tooltip: 'Phát âm tiếng Anh',
                icon: const Icon(
                  Icons.volume_up_outlined,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          const Text(
            'Mặt sau',
            style: TextStyle(
              color: Color(0xFF9AA0A6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            card.back,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF3C4043),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: const Color(0xFF9AA0A6),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}