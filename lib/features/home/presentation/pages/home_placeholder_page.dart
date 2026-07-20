import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/router/routes.dart';

class HomePlaceholderPage extends ConsumerWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref
        .watch(authControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final sets = ref.watch(setsProvider(''));
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Học flashcard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            user == null
                ? 'Đăng nhập để lưu tiến độ học.'
                : 'Xin chào ${user.username}',
          ),
          const SizedBox(height: 16),
          sets.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('$error'),
            data: (items) => items.isEmpty
                ? Card(
                    child: ListTile(
                      title: const Text('Chưa có bộ thẻ'),
                      subtitle: const Text(
                        'Tạo bộ thẻ đầu tiên trong Thư viện.',
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => context.go(kLibraryRoute),
                    ),
                  )
                : Column(
                    children: items
                        .map(
                          (set) => Card(
                            child: ListTile(
                              title: Text(set.title),
                              subtitle: Text('${set.cardCount} thẻ'),
                              trailing: const Icon(Icons.play_arrow),
                              onTap: () async {
                                final cards = await ref
                                    .read(repositoryProvider)
                                    .cards(set.id);
                                if (!context.mounted) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => _StudyPage(
                                      set: set,
                                      cards: cards,
                                      userId: user?.id,
                                    ),
                                  ),
                                );
                                ref.invalidate(learningHistoryProvider);
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (user != null) ...[
            const SizedBox(height: 20),
            Text(
              'Lịch sử học',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            ref
                .watch(learningHistoryProvider(user.id))
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text('$error'),
                  data: (rows) => Column(
                    children: rows
                        .map(
                          (row) => ListTile(
                            title: Text(row['title'] as String),
                            subtitle: Text(
                              'Thuộc ${row['known_count']} - Chưa thuộc ${row['unknown_count']}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _StudyPage extends StatefulWidget {
  const _StudyPage({
    required this.set,
    required this.cards,
    required this.userId,
  });

  final FlashcardSet set;
  final List<Flashcard> cards;
  final String? userId;

  @override
  State<_StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<_StudyPage> {
  int _index = 0;
  int _known = 0;
  int _unknown = 0;
  bool _back = false;

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const Scaffold(body: Center(child: Text('Bộ thẻ trống.')));
    }
    final done = _index >= widget.cards.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.set.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: done
            ? _Result(
                setId: widget.set.id,
                userId: widget.userId,
                known: _known,
                unknown: _unknown,
              )
            : _card(),
      ),
    );
  }

  Widget _card() {
    final card = widget.cards[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_index + 1}/${widget.cards.length} - Thuộc $_known - Chưa thuộc $_unknown',
        ),
        const SizedBox(height: 16),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _back = !_back),
            child: Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _back ? card.back : card.front,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _next(false),
                child: const Text('Chưa thuộc'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _next(true),
                child: const Text('Đã thuộc'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _next(bool known) {
    setState(() {
      if (known) {
        _known++;
      } else {
        _unknown++;
      }
      _index++;
      _back = false;
    });
  }
}

class _Result extends ConsumerStatefulWidget {
  const _Result({
    required this.setId,
    required this.userId,
    required this.known,
    required this.unknown,
  });

  final String setId;
  final String? userId;
  final int known;
  final int unknown;

  @override
  ConsumerState<_Result> createState() => _ResultState();
}

class _ResultState extends ConsumerState<_Result> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    if (!_saved && widget.userId != null) {
      _saved = true;
      Future.microtask(
        () => ref
            .read(repositoryProvider)
            .saveLearningResult(
              userId: widget.userId!,
              setId: widget.setId,
              known: widget.known,
              unknown: widget.unknown,
            ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Kết quả buổi học',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text('Đã thuộc: ${widget.known}'),
        Text('Chưa thuộc: ${widget.unknown}'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hoàn thành'),
        ),
      ],
    );
  }
}
