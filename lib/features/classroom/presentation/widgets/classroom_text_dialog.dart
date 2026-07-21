import 'package:flutter/material.dart';

/// Dialog with a [TextEditingController] owned by State (safe dispose).
Future<String?> showClassroomTextDialog({
  required BuildContext context,
  required String title,
  String label = '',
  String hint = '',
  String initialValue = '',
  String confirmLabel = 'OK',
  TextInputType keyboardType = TextInputType.text,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ClassroomTextDialog(
      title: title,
      label: label,
      hint: hint,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      keyboardType: keyboardType,
    ),
  );
}

class _ClassroomTextDialog extends StatefulWidget {
  const _ClassroomTextDialog({
    required this.title,
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.keyboardType,
  });

  final String title;
  final String label;
  final String hint;
  final String initialValue;
  final String confirmLabel;
  final TextInputType keyboardType;

  @override
  State<_ClassroomTextDialog> createState() => _ClassroomTextDialogState();
}

class _ClassroomTextDialogState extends State<_ClassroomTextDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.label.isEmpty ? null : widget.label,
          hintText: widget.hint.isEmpty ? null : widget.hint,
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  void _confirm() {
    Navigator.pop(context, _controller.text.trim());
  }
}
