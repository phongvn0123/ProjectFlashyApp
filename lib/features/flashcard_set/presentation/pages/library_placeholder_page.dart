import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';

class LibraryPlaceholderPage extends ConsumerStatefulWidget {
  const LibraryPlaceholderPage({super.key});

  @override
  ConsumerState<LibraryPlaceholderPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPlaceholderPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sets = ref.watch(setsProvider(_query.text));
    final user = ref
        .watch(authControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    return Scaffold(
      appBar: AppBar(title: const Text('Thư viện')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: user == null ? null : () => _showSetForm(context, user.id),
        icon: const Icon(Icons.add),
        label: const Text('Bộ thẻ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Tìm bộ thẻ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          sets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('$error'),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('Chưa có bộ thẻ nào.'));
              }
              return Column(
                children: items.map((set) => _SetCard(set: set)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showSetForm(BuildContext context, String userId) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final front = TextEditingController();
    final back = TextEditingController();
    final cards = <(String, String)>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Tạo bộ thẻ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: front,
                decoration: const InputDecoration(labelText: 'Mặt trước'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: back,
                decoration: const InputDecoration(labelText: 'Mặt sau'),
              ),
              TextButton.icon(
                onPressed: () {
                  if (front.text.trim().isEmpty || back.text.trim().isEmpty) {
                    return;
                  }
                  setSheetState(() {
                    cards.add((front.text, back.text));
                    front.clear();
                    back.clear();
                  });
                },
                icon: const Icon(Icons.add_card),
                label: Text('Thêm thẻ (${cards.length})'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty || cards.isEmpty) {
                    return;
                  }
                  await ref
                      .read(repositoryProvider)
                      .createSet(
                        ownerId: userId,
                        title: title.text,
                        description: description.text,
                        cards: cards,
                      );
                  ref.invalidate(setsProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Lưu bộ thẻ'),
              ),
            ],
          ),
        ),
      ),
    );
    title.dispose();
    description.dispose();
    front.dispose();
    back.dispose();
  }
}

class _SetCard extends ConsumerWidget {
  const _SetCard({required this.set});

  final FlashcardSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        title: Text(set.title),
        subtitle: Text('${set.cardCount} thẻ - ${set.visibility}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(set.description),
            ),
          ),
          ref
              .watch(cardsProvider(set.id))
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => ListTile(title: Text('$error')),
                data: (cards) => Column(
                  children: cards
                      .map(
                        (card) => ListTile(
                          title: Text(card.front),
                          subtitle: Text(card.back),
                        ),
                      )
                      .toList(),
                ),
              ),
        ],
      ),
    );
  }
}
