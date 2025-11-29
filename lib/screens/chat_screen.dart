import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/rating_provider.dart';
import '../widgets/rating_dialog.dart';
import '../models/message_model.dart';
import '../utils/security_utils.dart';
import '../widgets/tutoring_request_dialog.dart';
import '../widgets/ui/empty_state.dart';
import '../services/interaction_logger.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _userRole; // user role: student/parent/tutor
  String? _receiverRole; // receiver role
  final ScrollController _scrollController = ScrollController();
  final firebase_auth.User? _currentUser =
      firebase_auth.FirebaseAuth.instance.currentUser;

  bool _isValidChat = true;
  bool _hasMarkedAsRead = false;
  Stream<List<Message>>? _messageStream; // ✅ cache the stream here

  @override
  void initState() {
    super.initState();
    _validateChatAccess();

    // ✅ initialize message stream once
    if (_currentUser != null) {
      _messageStream = Provider.of<MessageProvider>(
        context,
        listen: false,
      ).getMessages(_currentUser!.uid, widget.receiverId);
    }
    // Load role regardless; method guards null internally
    _loadUserRole();
    _loadReceiverRole();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _markMessagesAsRead();
    });
  }

  Future<void> _loadUserRole() async {
    try {
      if (_currentUser == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          _userRole = (doc.data()?['role'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  bool get _isStudentOrParent =>
      _userRole == 'student' || _userRole == 'parent';

  bool get _receiverIsTutor => _receiverRole == 'tutor';

  void _validateChatAccess() {
    if (_currentUser == null ||
        !SecurityUtils.isValidUserId(widget.receiverId) ||
        !SecurityUtils.isValidUserId(_currentUser!.uid)) {
      setState(() => _isValidChat = false);
    }
  }

  Future<void> _loadReceiverRole() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          _receiverRole = (doc.data()?['role'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  void _openRating() async {
    if (_currentUser == null) return;
    final ratingProvider = Provider.of<RatingProvider>(context, listen: false);
    final myRating = await ratingProvider
        .getMyRating(widget.receiverId, _currentUser!.uid)
        .first;
    final initialScore = (myRating?['score'] ?? 5) as int;
    final initialComment = myRating?['comment'] as String?;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => RatingDialog(
        initialScore: initialScore,
        initialComment: initialComment,
        onSubmit: (score, comment) async {
          await ratingProvider.submitRating(
            tutorId: widget.receiverId,
            raterId: _currentUser!.uid,
            score: score,
            comment: comment,
            raterRole: _userRole,
          );
          InteractionLogger.log(
            event: 'rating_given',
            tutorId: widget.receiverId,
            data: {'score': score, 'comment': comment},
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUser == null || _hasMarkedAsRead) return;

    _hasMarkedAsRead = true;

    try {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      await messageProvider.markMessagesAsRead(
          _currentUser!.uid, widget.receiverId);
    } catch (error) {}
  }

  Future<String> _getRealUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data()?['name'] != null) {
        return doc.data()!['name'];
      }
    } catch (_) {}
    return 'User';
  }

  Future<int?> _getUserAge(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data()?['age'] != null) {
        return int.tryParse(doc.data()!['age'].toString());
      }
    } catch (_) {}
    return null;
  }

  void _sendMessage() {
    if (!_isValidChat || _currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send message: Security error')),
        );
      }
      return;
    }

    final message = SecurityUtils.sanitizeMessage(_messageController.text);
    if (message.isEmpty) return;

    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);

    _getRealUserName(_currentUser!.uid).then((realUserName) {
      messageProvider
          .sendMessage(
        senderId: _currentUser!.uid,
        senderName: realUserName,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        content: message,
      )
          .then((_) {
        if (mounted) {
          _messageController.clear();
          _scrollToBottom();
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send: $error')),
          );
        }
      });
    });
  }

  Future<void> _sendTutoringRequest() async {
    if (!_isValidChat || _currentUser == null) return;
    if (!_isStudentOrParent || !_receiverIsTutor) return;

    final currentUserName = await _getRealUserName(_currentUser!.uid);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => TutoringRequestDialog(
        fromUserId: _currentUser!.uid,
        fromUserName: currentUserName,
        toUserId: widget.receiverId,
        toUserName: widget.receiverName,
        onRequestSent: (request) async {
          final messageProvider =
              Provider.of<MessageProvider>(context, listen: false);
          final notificationProvider =
              Provider.of<NotificationProvider>(context, listen: false);
          try {
            await messageProvider.createTutoringRequest(request);
            await notificationProvider.createNotification(
              userId: widget.receiverId,
              title: 'New tutoring request',
              body: '$currentUserName wants to start tutoring with you.',
              type: 'tutoring_request',
              data: {
                'requestId': request.id,
                'studentId': request.studentId,
              },
            );
            await messageProvider.sendMessage(
              senderId: _currentUser!.uid,
              senderName: currentUserName,
              receiverId: widget.receiverId,
              receiverName: widget.receiverName,
              content: request.message.isNotEmpty
                  ? 'Tutoring request: ${request.message}'
                  : 'Sent a tutoring request',
            );
            if (mounted) {
              InteractionLogger.log(
                event: 'send_tutoring_request',
                tutorId: widget.receiverId,
                data: {
                  'studentId': request.studentId,
                  'subjects': request.subjects,
                },
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Tutoring request sent to ${widget.receiverName}.')),
              );
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Failed to send tutoring request: $error')),
              );
            }
          }
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidChat) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Cannot access this chat due to security restrictions'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.receiverName.substring(0, 1),
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.receiverName),
          ],
        ),
        actions: [
          if (_isStudentOrParent && _receiverIsTutor)
            IconButton(
              tooltip: 'Rate tutor',
              icon: const Icon(Icons.star_rate_rounded),
              onPressed: _openRating,
            ),
          if (_isStudentOrParent && _receiverIsTutor)
            IconButton(
              icon: const Icon(Icons.school),
              color: Colors.blue.shade700,
              tooltip: 'Request Tutoring',
              onPressed: _sendTutoringRequest,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentUser == null
                ? const Center(child: Text('Please log in to view messages.'))
                : StreamBuilder<List<Message>>(
                    stream: _messageStream, // ✅ use cached stream
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const EmptyState(
                          icon: Icons.forum_outlined,
                          title: 'No messages yet',
                          message: 'Say hello and start the conversation',
                        );
                      }

                      final messages = snapshot.data!;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == _currentUser!.uid;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      message.senderName.substring(0, 1),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            message.senderName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _formatTime(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
