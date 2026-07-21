import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sửa đường dẫn import này theo file detail/library của bạn.
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/memocard_models.dart';
class CreateFlashcardSetPage extends ConsumerStatefulWidget {
  const CreateFlashcardSetPage({
    super.key,
    this.initialSet,
    this.initialCards = const [],
  });

  final FlashcardSet? initialSet;
  final List<Flashcard> initialCards;

  bool get isEditing => initialSet != null;

  @override
  ConsumerState<CreateFlashcardSetPage> createState() =>
      _CreateFlashcardSetPageState();
}

class _CreateFlashcardSetPageState
    extends ConsumerState<CreateFlashcardSetPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // final List<_CardInput> _cards = [
  //   _CardInput(),
  //   _CardInput(),
  // ];
  final List<_CardInput> _cards = [];
  String _visibility = 'public';
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();

    final initialSet = widget.initialSet;

    if (initialSet != null) {
      _titleController.text = initialSet.title;
      _descriptionController.text = initialSet.description;
      _visibility = initialSet.visibility;

      for (final card in widget.initialCards) {
        _cards.add(
          _CardInput(
            front: card.front,
            back: card.back,
          ),
        );
      }
    }

    // Khi tạo mới thì mặc định có 2 ô thẻ.
    if (_cards.isEmpty) {
      _cards.addAll([
        _CardInput(),
        _CardInput(),
      ]);
    }
  }
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    for (final card in _cards) {
      card.dispose();
    }

    super.dispose();
  }

  void _addCard() {
    setState(() {
      _cards.add(_CardInput());
    });
  }

  void _removeCard(int index) {
    if (_cards.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bộ thẻ phải có ít nhất một thẻ.'),
        ),
      );
      return;
    }

    final removedCard = _cards.removeAt(index);
    removedCard.dispose();

    setState(() {});
  }

  Future<void> _saveSet() async {
    if (_isSaving) return;

    final user = ref.read(authControllerProvider).asData?.value;
    final title = _titleController.text.trim();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin người dùng.'),
        ),
      );
      return;
    }

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn chưa nhập tiêu đề bộ thẻ.'),
        ),
      );
      return;
    }

    final validCards = <(String, String)>[];

    for (var index = 0; index < _cards.length; index++) {
      final front = _cards[index].frontController.text.trim();
      final back = _cards[index].backController.text.trim();

      // Bỏ qua thẻ trống hoàn toàn.
      if (front.isEmpty && back.isEmpty) {
        continue;
      }

      // Nếu mới nhập một mặt thì báo lỗi.
      if (front.isEmpty || back.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thẻ ${index + 1} phải có đủ mặt trước và mặt sau.',
            ),
          ),
        );
        return;
      }

      validCards.add((front, back));
    }

    if (validCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần nhập ít nhất một thẻ ghi nhớ.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(repositoryProvider);

      if (widget.isEditing) {
        await repository.updateSet(
          setId: widget.initialSet!.id,
          title: title,
          description: _descriptionController.text.trim(),
          visibility: _visibility,
          cards: validCards,
        );
      } else {
        await repository.createSet(
          ownerId: user.id,
          title: title,
          description: _descriptionController.text.trim(),
          visibility: _visibility,
          cards: validCards,
        );
      }

      if (!mounted) return;

      // Trả true để trang Library biết cần tải lại dữ liệu.
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Không thể cập nhật bộ thẻ: $error'
                : 'Không thể tạo bộ thẻ: $error',
          ),        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _isSaving
              ? null
              : () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close),
        ),
        title: Text(
          widget.isEditing ? 'Chỉnh sửa bộ thẻ' : 'Tạo bộ thẻ',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isSaving ? null : _saveSet,
              style: FilledButton.styleFrom(
                minimumSize: const Size(68, 38),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Text('Lưu'),
            ),
          ),
        ],
      ),
        body: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  160, // Chừa chỗ cho thanh menu dưới
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            _SectionLabel(text: 'Tiêu đề bộ thẻ'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                hintText: 'Nhập tiêu đề, ví dụ: Từ vựng tiếng Anh',
              ),
            ),

            const SizedBox(height: 18),

            _SectionLabel(text: 'Mô tả bộ thẻ'),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: _inputDecoration(
                hintText: 'Thêm mô tả ngắn gọn về nội dung bộ thẻ...',
              ),
            ),

            const SizedBox(height: 18),

            _SectionLabel(text: 'Hiển thị'),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Mọi người'),
                  avatar: const Icon(
                    Icons.public,
                    size: 18,
                  ),
                  selected: _visibility == 'public',
                  onSelected: (_) {
                    setState(() {
                      _visibility = 'public';
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Chỉ mình'),
                  avatar: const Icon(
                    Icons.lock_outline,
                    size: 18,
                  ),
                  selected: _visibility == 'private',
                  onSelected: (_) {
                    setState(() {
                      _visibility = 'private';
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            Text(
              'Thẻ (${_cards.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            for (var index = 0; index < _cards.length; index++) ...[
              _FlashcardInputCard(
                number: index + 1,
                input: _cards[index],
                canDelete: _cards.length > 1,
                onDelete: () => _removeCard(index),
              ),
              const SizedBox(height: 14),
            ],

            OutlinedButton.icon(
              onPressed: _isSaving ? null : _addCard,
              icon: const Icon(Icons.add),
              label: const Text('Thêm thẻ'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(
                  color: Color(0xFFCCD6EF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
            ),
        ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA0AE),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E6EF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E6EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF246BCE),
          width: 1.5,
        ),
      ),
    );
  }
}

class _FlashcardInputCard extends StatelessWidget {
  const _FlashcardInputCard({
    required this.number,
    required this.input,
    required this.canDelete,
    required this.onDelete,
  });

  final int number;
  final _CardInput input;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 27,
                height: 27,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF1FC),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Color(0xFF246BCE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: canDelete ? onDelete : null,
                tooltip: 'Xóa thẻ',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  color: canDelete
                      ? const Color(0xFFD84A4A)
                      : Colors.grey.shade300,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'MẶT TRƯỚC',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF7A8190),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          TextField(
            controller: input.frontController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Nhập từ hoặc câu hỏi...',
              border: UnderlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'MẶT SAU',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF7A8190),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          TextField(
            controller: input.backController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Nhập nghĩa hoặc câu trả lời...',
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF252A34),
      ),
    );
  }
}

class _CardInput {
  _CardInput({
    String front = '',
    String back = '',
  })  : frontController = TextEditingController(text: front),
        backController = TextEditingController(text: back);

  final TextEditingController frontController;
  final TextEditingController backController;

  void dispose() {
    frontController.dispose();
    backController.dispose();
  }
}