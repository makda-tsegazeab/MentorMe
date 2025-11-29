import 'package:flutter/material.dart';
import '../models/tutoring_request.dart';

class TutoringRequestDialog extends StatefulWidget {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final Future<void> Function(TutoringRequest request) onRequestSent;

  const TutoringRequestDialog({
    super.key,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.onRequestSent,
  });

  @override
  State<TutoringRequestDialog> createState() => _TutoringRequestDialogState();
}

class _TutoringRequestDialogState extends State<TutoringRequestDialog> {
  final _messageController = TextEditingController();
  final _subjectsController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendRequest() async {
    if (_isSending) return;
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe why you need tutoring.')),
      );
      return;
    }

    final subjectText = _subjectsController.text.trim();
    final subjects = subjectText
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();

    setState(() => _isSending = true);
    final request = TutoringRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: widget.fromUserId,
      studentName: widget.fromUserName,
      tutorId: widget.toUserId,
      tutorName: widget.toUserName,
      message: message,
      subjects: subjects,
    );

    try {
      await widget.onRequestSent(request);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subjectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.school, color: cs.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Request Tutoring',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tutor: ${widget.toUserName}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: cs.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Explain what you need help with (required)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectsController,
              decoration: const InputDecoration(
                hintText: 'Subjects (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Optional subjects / topics help the tutor prepare.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendRequest,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }
}
