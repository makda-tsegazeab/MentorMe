import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/booking_request.dart';
import '../models/tutoring_request.dart';

class MessageProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================== MESSAGE METHODS ==================
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String content,
  }) async {
    try {
      final participants = [senderId, receiverId]..sort();

      await _firestore.collection('messages').add({
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'content': content,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'participants': participants,
      });
    } catch (error) {
      throw Exception('Failed to send message: $error');
    }
  }

  Stream<List<Message>> getConversations(String userId) {
    return _firestore
        .collection('messages')
        .where('participants', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      final allMessages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .where((m) => m.senderId.isNotEmpty && m.receiverId.isNotEmpty)
          .toList();

      final conversationMap = <String, Message>{};
      for (final msg in allMessages) {
        final otherUserId =
            msg.senderId == userId ? msg.receiverId : msg.senderId;
        if (!conversationMap.containsKey(otherUserId) ||
            msg.timestamp.isAfter(conversationMap[otherUserId]!.timestamp)) {
          conversationMap[otherUserId] = msg;
        }
      }

      return conversationMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Stream<List<Message>> getMessages(String currentUserId, String otherUserId) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [currentUserId, otherUserId])
        .where('receiverId', whereIn: [currentUserId, otherUserId])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> markMessagesAsRead(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final query = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      if (query.docs.isNotEmpty) await batch.commit();

      notifyListeners();
    } catch (error) {}
  }

  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) => 0);
  }

  // ================== FIX UTILITIES ==================
  Future<void> addParticipantsToExistingMessages() async {
    try {
      final snapshot = await _firestore.collection('messages').get();
      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'];
        final receiverId = data['receiverId'];
        if (senderId != null &&
            receiverId != null &&
            data['participants'] == null) {
          final participants = [senderId, receiverId]..sort();
          batch.update(doc.reference, {'participants': participants});
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
      }
    } catch (error) {}
  }

  Future<void> fixMessageNames() async {
    try {
      final snapshot = await _firestore.collection('messages').get();
      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'];
        if (senderId != null) {
          final userDoc =
              await _firestore.collection('users').doc(senderId).get();
          if (userDoc.exists) {
            final realName = userDoc.data()?['name'];
            if (realName != null && realName != data['senderName']) {
              batch.update(doc.reference, {'senderName': realName});
              updatedCount++;
            }
          }
        }
      }
      if (updatedCount > 0) {
        await batch.commit();
      }
    } catch (error) {}
  }

  // ================== TUTORING REQUEST METHODS ==================
  Future<void> createTutoringRequest(TutoringRequest request) async {
    try {
      await _firestore
          .collection('tutoringRequests')
          .doc(request.id)
          .set(request.toMap());
    } catch (error) {
      throw Exception('Failed to create tutoring request: $error');
    }
  }

  Stream<List<TutoringRequest>> getTutoringRequestsForTutor(String tutorId) {
    return _firestore
        .collection('tutoringRequests')
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TutoringRequest.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<TutoringRequest>> getTutoringRequestsForStudent(String studentId) {
    return _firestore
        .collection('tutoringRequests')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TutoringRequest.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> updateTutoringRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _firestore.collection('tutoringRequests').doc(requestId).update({
        'status': status,
      });
    } catch (error) {
      throw Exception('Failed to update tutoring request: $error');
    }
  }

  // ================== RELATIONSHIP METHODS ==================
  Future<void> createTutoringRelationship({
    required String tutorId,
    required String studentId,
    required String tutorName,
    required String studentName,
    List<String> subjects = const [],
    int sessionsPerWeek = 0,
    int hoursPerSession = 0,
    String agreementNotes = '',
    Timestamp? startedAt,
  }) async {
    try {
      final relationshipId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore
          .collection('tutoringRelationships')
          .doc(relationshipId)
          .set({
        'id': relationshipId,
        'tutorId': tutorId,
        'studentId': studentId,
        'tutorName': tutorName,
        'studentName': studentName,
        'status': 'active',
        if (startedAt != null) 'startedAt': startedAt,
        'subjects': subjects,
        'sessionsPerWeek': sessionsPerWeek,
        'hoursPerSession': hoursPerSession,
        'agreementNotes': agreementNotes,
        'createdAt': Timestamp.now(),
      });
    } catch (error) {}
  }

  // ================== BOOKING REQUEST METHODS ==================
  Future<void> createBookingRequest(BookingRequest request) async {
    await _firestore
        .collection('bookingRequests')
        .doc(request.id)
        .set(request.toMap());
  }

  Stream<List<BookingRequest>> getTutorBookingRequests(String tutorId) {
    return _firestore
        .collection('bookingRequests')
        .where('tutorId', isEqualTo: tutorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingRequest.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<BookingRequest>> getStudentBookingRequests(String studentId) {
    return _firestore
        .collection('bookingRequests')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingRequest.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> respondBookingRequest({
    required BookingRequest request,
    required String status,
  }) async {
    await _firestore
        .collection('bookingRequests')
        .doc(request.id)
        .update({'status': status});

    if (status == 'approved') {
      await createTutoringRelationship(
        tutorId: request.tutorId,
        studentId: request.studentId,
        tutorName: request.tutorName,
        studentName: request.studentName,
        subjects: request.subjects,
        sessionsPerWeek: request.sessionsPerWeek,
        hoursPerSession: request.hoursPerSession,
        agreementNotes: request.agreementNotes,
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getTutoringRelationships(String userId) {
    return _firestore
        .collection('tutoringRelationships')
        .where('status', isEqualTo: 'active')
        .where('tutorId', isEqualTo: userId)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getStudentRelationships(String userId) {
    return _firestore
        .collection('tutoringRelationships')
        .where('status', isEqualTo: 'active')
        .where('studentId', isEqualTo: userId)
        .snapshots()
        .handleError((error) => Stream.value([]))
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
