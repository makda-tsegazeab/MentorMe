import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/tutoring_request.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/ui/empty_state.dart' as ui;

class RelationshipsScreen extends StatefulWidget {
  const RelationshipsScreen({super.key});

  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> {
  String? _userId;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    String role = 'student';
    if (snapshot.exists && snapshot.data()?['role'] != null) {
      role = snapshot.data()!['role'].toString();
    } else {
      final tutorDoc = await FirebaseFirestore.instance
          .collection('tutors')
          .doc(currentUser.uid)
          .get();
      if (tutorDoc.exists) role = 'tutor';
    }

    if (mounted) {
      setState(() {
        _userRole = role;
        _userId = currentUser.uid;
        _isLoading = false;
      });
    }
  }

  bool get _isTutor => _userRole == 'tutor';
  bool get _isLearner => _userRole == 'student' || _userRole == 'parent';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to see your tutoring requests.'),
        ),
      );
    }

    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    final requestsStream = _isTutor
        ? messageProvider.getTutoringRequestsForTutor(_userId!)
        : messageProvider.getTutoringRequestsForStudent(_userId!);
    final relationshipsStream = _isTutor
        ? messageProvider.getTutoringRelationships(_userId!)
        : messageProvider.getStudentRelationships(_userId!);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: StreamBuilder<List<TutoringRequest>>(
            stream: requestsStream,
            builder: (context, snapshot) {
              final requests = snapshot.data ?? [];
              final sortedRequests = List<TutoringRequest>.from(requests)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tutoring Requests',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (sortedRequests.isEmpty)
                      const ui.EmptyState(
                        icon: Icons.class_,
                        title: 'No tutoring requests yet',
                        message:
                            'Pending requests will show up here for tutors and learners.',
                      )
                    else
                      ...sortedRequests.map(_buildRequestCard),
                    const SizedBox(height: 24),
                    Text(
                      'Active Relationships',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: relationshipsStream,
                      builder: (context, relSnapshot) {
                        final relationships = relSnapshot.data ?? [];
                        if (relationships.isEmpty) {
                          return const ui.EmptyState(
                            icon: Icons.handshake,
                            title: 'No active relationships',
                            message:
                                'Approved relationships will appear here once a tutor accepts your request.',
                          );
                        }
                        return Column(
                          children: relationships
                              .map(_buildRelationshipCard)
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(TutoringRequest request) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(request.status);
    final displayStatus = request.status[0].toUpperCase() +
        request.status.substring(1).replaceAll('_', ' ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isTutor ? request.studentName : request.tutorName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.message,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (request.subjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: request.subjects
                    .map((subject) => Chip(
                          label: Text(subject),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd()
                      .add_jm()
                      .format(request.createdAt.toDate()),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (_isTutor && request.status == 'pending')
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _respondToRequest(
                          request,
                          approve: false,
                        ),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _respondToRequest(
                          request,
                          approve: true,
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipCard(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final partnerName = _isTutor ? data['studentName'] : data['tutorName'];
    final partnerRole = _isTutor ? 'Student' : 'Tutor';
    final startedAt = data['startedAt'] as Timestamp?;
    final startedLabel = startedAt != null
        ? DateFormat.yMMMd().format(startedAt.toDate())
        : 'Awaiting start';
    final status = (data['status'] ?? 'active').toString();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              partnerName ?? 'Learner',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              partnerRole,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text('Start: $startedLabel'),
            const SizedBox(height: 4),
            Text('Status: ${status[0].toUpperCase()}${status.substring(1)}'),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToRequest(TutoringRequest request,
      {required bool approve}) async {
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    try {
      await messageProvider.updateTutoringRequestStatus(
        requestId: request.id,
        status: approve ? 'approved' : 'declined',
      );
      if (approve) {
        await messageProvider.createTutoringRelationship(
          tutorId: request.tutorId,
          studentId: request.studentId,
          tutorName: request.tutorName,
          studentName: request.studentName,
          subjects: request.subjects,
          agreementNotes: request.message,
          startedAt: Timestamp.now(),
        );
      }

      await notificationProvider.createNotification(
        userId: request.studentId,
        title:
            approve ? 'Tutoring request approved' : 'Tutoring request declined',
        body: approve
            ? '${request.tutorName} accepted your tutoring request.'
            : '${request.tutorName} declined your tutoring request.',
        type:
            approve ? 'tutoring_request_approved' : 'tutoring_request_declined',
        data: {
          'requestId': request.id,
          'tutorId': request.tutorId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Tutoring relationship activated.'
                : 'Request declined.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update request: $error')),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade700;
      case 'declined':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade700;
    }
  }
}
