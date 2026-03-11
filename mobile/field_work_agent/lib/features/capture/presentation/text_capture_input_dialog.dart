import 'package:flutter/material.dart';

class TextCaptureInputDialog extends StatefulWidget {
  const TextCaptureInputDialog({super.key});

  @override
  State<TextCaptureInputDialog> createState() => _TextCaptureInputDialogState();
}

class _TextCaptureInputDialogState extends State<TextCaptureInputDialog> {
  late TextEditingController _textController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isValid = _textController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paste Text'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Enter text to capture as a task:'),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Enter text here',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? () => Navigator.pop(context, _textController.text) : null,
          child: const Text('Capture'),
        ),
      ],
    );
  }
}
