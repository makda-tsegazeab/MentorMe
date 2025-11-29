// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import '../providers/message_provider.dart';
// import '../screens/chat_screen.dart';
// import '../models/message_model.dart';
// import '../screens/relationships_screen.dart';
// import 'dart:async'; // Added for StreamController and debounce
// import '../models/notification_model.dart';
// import '../providers/notification_provider.dart';
// import '../widgets/ui/rating_badge.dart';
// import '../theme/app_theme.dart';
// import '../widgets/ui/empty_state.dart' as ui;
// import '../services/interaction_logger.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   String? _userName;
//   String? _userRole;
//   String? _profileImage;
//   bool _isDarkMode = false;

//   // Search filters
//   String _selectedSubject = 'All Subjects';
//   String _selectedGrade = 'All Grades';
//   double _priceRange = 500;
//   bool _onlyVerified = true;
//   String _searchQuery = '';

//   bool _isLoadingRecommendations = false;
//   String? _recommendationsError;
//   List<Map<String, dynamic>> _recommendedTutors = [];

//   final List<String> _subjects = [
//     'All Subjects',
//     'Mathematics',
//     'English',
//     'Amharic',
//     'Tigrigna',
//     'Physics',
//     'Chemistry',
//     'Biology',
//     'ICT',
//   ];

//   final List<String> _grades = [
//     'All Grades',
//     'KG',
//     '1–4',
//     '5–6',
//     '7–8',
//     '9–10',
//     '11–12',
//   ];

//   // Debounce timer for search
//   Timer? _debounce;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     _loadRecommendations();
//     // Reset search query on new session to clear any stale state
//     _searchQuery = '';
//   }

//   Future<void> _loadUserData() async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       var doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();

//       if (doc.exists) {
//         setState(() {
//           _userRole = doc.data()?['role'];
//           _userName = doc.data()?['name'];
//           _profileImage = doc.data()?['profileImage'];
//         });
//       } else {
//         doc = await FirebaseFirestore.instance
//             .collection('tutors')
//             .doc(user.uid)
//             .get();

//         if (doc.exists) {
//           setState(() {
//             _userRole = 'tutor';
//             _userName = doc.data()?['name'];
//             _profileImage = doc.data()?['profileImage'];
//           });
//         }
//       }
//     }
//   }

//   // Future<void> _loadRecommendations() async {
//   //   final user = firebase_auth.FirebaseAuth.instance.currentUser;
//   //   if (user == null) {
//   //     debugPrint('🔥 _loadRecommendations: no current user');
//   //     return;
//   //   }

//   //   if (!mounted) return;

//   //   setState(() {
//   //     _isLoadingRecommendations = true;
//   //     _recommendationsError = null;
//   //   });

//   //   try {
//   //     debugPrint('🔍 Loading recommendations for uid=${user.uid}');

//   //     final doc = await FirebaseFirestore.instance
//   //         .collection('recommendations')
//   //         .doc(user.uid)
//   //         .get(const GetOptions(source: Source.server));

//   //     debugPrint('📄 recommendations/${user.uid} exists: ${doc.exists}');
//   //     debugPrint('📄 raw data: ${doc.data()}');

//   //     if (!doc.exists) {
//   //       // No doc at all for this user
//   //       if (!mounted) return;
//   //       setState(() {
//   //         _recommendedTutors = [];
//   //         _recommendationsError = null; // “no personalized tutors yet” state
//   //       });
//   //       return;
//   //     }

//   //     final data = doc.data();
//   //     if (data == null) {
//   //       if (!mounted) return;
//   //       setState(() {
//   //         _recommendedTutors = [];
//   //         _recommendationsError = null;
//   //       });
//   //       return;
//   //     }

//   //     // Be defensive about types
//   //     final rawItemsDynamic = data['items'];
//   //     if (rawItemsDynamic == null) {
//   //       debugPrint('⚠️ "items" field missing in recommendations doc.');
//   //       if (!mounted) return;
//   //       setState(() {
//   //         _recommendedTutors = [];
//   //         _recommendationsError = null;
//   //       });
//   //       return;
//   //     }

//   //     if (rawItemsDynamic is! List) {
//   //       debugPrint(
//   //           '❌ "items" is not a List. Got: ${rawItemsDynamic.runtimeType}');
//   //       if (!mounted) return;
//   //       setState(() {
//   //         _recommendedTutors = [];
//   //         _recommendationsError =
//   //             'Invalid recommendations format (items is not a list)';
//   //       });
//   //       return;
//   //     }

//   //     final rawItems = rawItemsDynamic.cast<dynamic>();
//   //     debugPrint('✅ items length = ${rawItems.length}');

//   //     final items = <Map<String, dynamic>>[];
//   //     for (final item in rawItems) {
//   //       if (item is Map) {
//   //         items.add(Map<String, dynamic>.from(item as Map));
//   //       } else {
//   //         debugPrint('⚠️ Skipping non-map recommendation item: $item');
//   //       }
//   //     }

//   //     debugPrint('✅ Parsed ${items.length} recommendation maps');

//   //     if (!mounted) return;
//   //     setState(() {
//   //       _recommendedTutors = items;
//   //       _recommendationsError = null;
//   //     });
//   //   } catch (e, st) {
//   //     debugPrint('❌ Error loading recommendations: $e');
//   //     debugPrint('STACK:\n$st');

//   //     if (!mounted) return;
//   //     setState(() {
//   //       _recommendedTutors = [];
//   //       _recommendationsError = e.toString();
//   //     });
//   //   } finally {
//   //     if (!mounted) return;
//   //     setState(() => _isLoadingRecommendations = false);
//   //   }
//   // }
//   Future<void> _loadRecommendations() async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('🔥 _loadRecommendations: no current user');
//       return;
//     }

//     if (!mounted) return;

//     // Web workaround: Firestore web SDK 12.3.0 has a known watch-stream crash (ca9/b815).
//     // Skip recommendation fetch on web to prevent the assertion failure.
//     if (kIsWeb) {
//       setState(() {
//         _isLoadingRecommendations = false;
//         _recommendedTutors = [];
//         _recommendationsError = null;
//       });
//       debugPrint(
//           'Skipping recommendations fetch on web (known Firestore web bug).');
//       return;
//     }

//     setState(() {
//       _isLoadingRecommendations = true;
//       _recommendationsError = null;
//     });

//     try {
//       debugPrint('🔍 Loading recommendations for uid=${user.uid}');

//       // 1️⃣ Get role (and update _userRole if it was null)
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get(const GetOptions(source: Source.server));

//       final role = (userDoc.data()?['role'] as String?) ?? 'student';
//       if (_userRole == null) {
//         setState(() {
//           _userRole = role;
//         });
//       }

//       // 2️⃣ Pick the right collection
//       final String recCollection =
//           role == 'tutor' ? 'tutor_recommendations' : 'recommendations';

//       debugPrint('📚 Using rec collection: $recCollection for role=$role');

//       // 3️⃣ Fetch the recommendation doc
//       final doc = await FirebaseFirestore.instance
//           .collection(recCollection)
//           .doc(user.uid)
//           .get(const GetOptions(source: Source.server));

//       debugPrint('📄 $recCollection/${user.uid} exists: ${doc.exists}');
//       debugPrint('📄 raw data: ${doc.data()}');

//       if (!doc.exists || doc.data() == null) {
//         if (!mounted) return;
//         setState(() {
//           _recommendedTutors = [];
//           _recommendationsError = null; // "no personalized X yet"
//         });
//         return;
//       }

//       final data = doc.data()!;
//       final rawItemsDynamic = data['items'];

//       if (rawItemsDynamic == null) {
//         debugPrint('⚠️ "items" field missing in $recCollection doc.');
//         if (!mounted) return;
//         setState(() {
//           _recommendedTutors = [];
//           _recommendationsError = null;
//         });
//         return;
//       }

//       if (rawItemsDynamic is! List) {
//         debugPrint(
//             '❌ "items" is not a List. Got: ${rawItemsDynamic.runtimeType}');
//         if (!mounted) return;
//         setState(() {
//           _recommendedTutors = [];
//           _recommendationsError =
//               'Invalid recommendations format (items is not a list)';
//         });
//         return;
//       }

//       final rawItems = rawItemsDynamic.cast<dynamic>();
//       debugPrint('✅ items length = ${rawItems.length}');

//       final items = <Map<String, dynamic>>[];
//       for (final item in rawItems) {
//         if (item is Map) {
//           items.add(Map<String, dynamic>.from(item as Map));
//         } else {
//           debugPrint('⚠️ Skipping non-map recommendation item: $item');
//         }
//       }

//       debugPrint('✅ Parsed ${items.length} recommendation maps');

//       if (!mounted) return;
//       setState(() {
//         _recommendedTutors = items;
//         _recommendationsError = null;
//       });
//     } catch (e, st) {
//       debugPrint('❌ Error loading recommendations: $e');
//       debugPrint('STACK:\n$st');

//       if (!mounted) return;
//       setState(() {
//         _recommendedTutors = [];
//         _recommendationsError = e.toString();
//       });
//     } finally {
//       if (!mounted) return;
//       setState(() => _isLoadingRecommendations = false);
//     }
//   }

//   // UPDATED: Role-based text methods
//   String _getWelcomeMessage() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Find learners that match your expertise';
//       case 'parent':
//         return 'Find the perfect tutor for your child';
//       case 'student':
//       default:
//         return 'Find the perfect tutor for your needs';
//     }
//   }

//   String _getMainTitle() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Find Learners';
//       case 'parent':
//       case 'student':
//       default:
//         return 'Find Tutors';
//     }
//   }

//   String _getSearchHintText() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Search students by name...';
//       case 'parent':
//       case 'student':
//       default:
//         return 'Search for tutors by name...';
//     }
//   }

//   String _getSearchTargetRole() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'student'; // Tutors search for students
//       case 'parent':
//         return 'tutor'; // Parents search for tutors
//       case 'student':
//       default:
//         return 'tutor'; // Students search for tutors
//     }
//   }

//   String _getSearchTargetCollection() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'users'; // Tutors search in users collection for students
//       case 'parent':
//       case 'student':
//       default:
//         return 'users'; // Students/parents search in users collection for tutors
//     }
//   }

//   String _getAIRecommendationTitle() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'AI Recommended Students';
//       case 'parent':
//       case 'student':
//       default:
//         return 'AI Recommended Tutors';
//     }
//   }

//   String _getAIRecommendationSubtitle() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Based on your expertise and teaching preferences';
//       case 'parent':
//       case 'student':
//       default:
//         return 'Based on your profile and learning preferences';
//     }
//   }

//   String _getTopRatedTitle() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Top Rated Students';
//       case 'parent':
//       case 'student':
//       default:
//         return 'Top Rated Tutors';
//     }
//   }

//   Widget _buildHomeTab() {
//     return Container(
//         color: Theme.of(context).brightness == Brightness.dark
//             ? AppTheme.backgroundDark
//             : AppTheme.backgroundLight,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header with theme toggle
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Hello, ${_userName ?? 'there'}! 👋",
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         _getWelcomeMessage(),
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   IconButton(
//                     onPressed: () {
//                       setState(() {
//                         _isDarkMode = !_isDarkMode;
//                       });
//                       _changeTheme(_isDarkMode);
//                     },
//                     icon: Icon(
//                       _isDarkMode ? Icons.light_mode : Icons.dark_mode,
//                       color: Colors.blue.shade700,
//                       size: 28,
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 30),

//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).brightness == Brightness.dark
//                         ? const Color(0xFF101922)
//                         : const Color(0xFFF6F7F8),
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 12,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 60,
//                         height: 56,
//                         decoration: BoxDecoration(
//                           color: Theme.of(context).brightness == Brightness.dark
//                               ? const Color(0xFF1F2434)
//                               : const Color(0xFFEFEFEF),
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(24),
//                             bottomLeft: Radius.circular(24),
//                           ),
//                         ),
//                         child: const Icon(
//                           Icons.search,
//                           color: Colors.grey,
//                           size: 28,
//                         ),
//                       ),
//                       Expanded(
//                         child: TextField(
//                           onChanged: (value) {
//                             if (_debounce?.isActive ?? false)
//                               _debounce!.cancel();
//                             _debounce =
//                                 Timer(const Duration(milliseconds: 500), () {
//                               setState(() {
//                                 _searchQuery = value;
//                               });
//                             });
//                           },
//                           style: TextStyle(
//                             color:
//                                 Theme.of(context).brightness == Brightness.dark
//                                     ? Colors.white
//                                     : Colors.black87,
//                           ),
//                           decoration: InputDecoration(
//                             hintText: 'Search tutors by name',
//                             hintStyle: TextStyle(
//                               color: Theme.of(context).brightness ==
//                                       Brightness.dark
//                                   ? Colors.grey.shade400
//                                   : Colors.grey.shade500,
//                             ),
//                             border: InputBorder.none,
//                             contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 18),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 30),

//               // Search Results Section
//               if (_searchQuery.isNotEmpty) ...[
//                 Text(
//                   'Search Results for "$_searchQuery"',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildSearchResults(),
//                 const SizedBox(height: 30),
//               ],

//               // AI Recommended Section
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     _getAIRecommendationTitle(),
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.auto_awesome,
//                           size: 16,
//                           color: Colors.blue.shade700,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           'AI Powered',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.blue.shade700,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _getAIRecommendationSubtitle(),
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // AI Recommended Cards - horizontal scroll (students for tutors, tutors for learners)
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(width: 4),
//                     ..._buildRecommendationCards(),
//                     const SizedBox(width: 4),
//                   ],
//                 ),
//               ),

//               if (_userRole == 'student' || _userRole == 'parent') ...[
//                 const SizedBox(height: 30),
//                 Text(
//                   _getTopRatedTitle(),
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTopRatedList(),
//               ],
//             ),
//           ),
//         ),
//       );

//   }

//   // Recommendation card for tutors viewing recommended students
//   // Widget _buildRecommendedStudentCard(Map<String, dynamic> rec) {
//   //   final name = (rec['name'] ?? 'Student').toString();
//   //   final studentId = (rec['studentId'] ?? '').toString();
//   //   final city = (rec['city'] ?? 'Location not set').toString();
//   //   final grade = rec['grade']?.toString() ?? 'Student';
//   //   final age = rec['age'];
//   //   final gender = rec['sex']?.toString();
//   //   final subjects = (rec['subjects'] as List<dynamic>? ?? []).cast<String>();
//   //   final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
//   //   final score = (rec['score'] as num?)?.toDouble() ?? 0.0;
//   //   final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
//   //   final highlight =
//   //       reasons.isNotEmpty ? reasons.first : 'Matches your expertise';
//   //   final subjectsText = subjects.isEmpty
//   //       ? 'Interests not provided'
//   //       : 'Interests: ${subjects.take(3).join(', ')}';

//   //   return Container(
//   //     width: 260,
//   //     child: Card(
//   //       elevation: 4,
//   //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//   //       child: Padding(
//   //         padding: const EdgeInsets.all(16),
//   //         child: Column(
//   //           crossAxisAlignment: CrossAxisAlignment.start,
//   //           children: [
//   //             Row(
//   //               children: [
//   //                 CircleAvatar(
//   //                   backgroundColor: Colors.blue.shade100,
//   //                   child: Text(
//   //                     name.substring(0, 1),
//   //                     style: const TextStyle(
//   //                       color: Colors.blue,
//   //                       fontWeight: FontWeight.bold,
//   //                     ),
//   //                   ),
//   //                 ),
//   //                 const SizedBox(width: 12),
//   //                 Expanded(
//   //                   child: Column(
//   //                     crossAxisAlignment: CrossAxisAlignment.start,
//   //                     children: [
//   //                       Text(
//   //                         name,
//   //                         style: const TextStyle(
//   //                           fontWeight: FontWeight.bold,
//   //                           fontSize: 16,
//   //                         ),
//   //                         maxLines: 1,
//   //                         overflow: TextOverflow.ellipsis,
//   //                       ),
//   //                       const SizedBox(height: 2),
//   //                       Text(
//   //                         [
//   //                           grade,
//   //                           if (age is num) 'Age ${age.toInt()}',
//   //                           if (gender != null && gender.isNotEmpty) gender,
//   //                           city,
//   //                         ].where((e) => e.isNotEmpty).join(' • '),
//   //                         style: TextStyle(
//   //                           fontSize: 12,
//   //                           color: Colors.grey.shade600,
//   //                         ),
//   //                         maxLines: 2,
//   //                         overflow: TextOverflow.ellipsis,
//   //                       ),
//   //                     ],
//   //                   ),
//   //                 ),
//   //                 Container(
//   //                   padding: const EdgeInsets.symmetric(
//   //                     horizontal: 8,
//   //                     vertical: 4,
//   //                   ),
//   //                   decoration: BoxDecoration(
//   //                     color: Colors.green.shade50,
//   //                     borderRadius: BorderRadius.circular(8),
//   //                   ),
//   //                   child: Text(
//   //                     '$matchPercent% match',
//   //                     style: TextStyle(
//   //                       fontSize: 11,
//   //                       color: Colors.green.shade700,
//   //                       fontWeight: FontWeight.bold,
//   //                     ),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //             const SizedBox(height: 12),
//   //             Text(
//   //               highlight,
//   //               style: const TextStyle(
//   //                 fontWeight: FontWeight.w600,
//   //                 fontSize: 13,
//   //               ),
//   //               maxLines: 2,
//   //               overflow: TextOverflow.ellipsis,
//   //             ),
//   //             const SizedBox(height: 8),
//   //             Text(
//   //               subjectsText,
//   //               style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
//   //               maxLines: 2,
//   //               overflow: TextOverflow.ellipsis,
//   //             ),
//   //             const SizedBox(height: 12),
//   //             Row(
//   //               children: [
//   //                 Expanded(
//   //                   child: OutlinedButton(
//   //                     onPressed: () {
//   //                       _viewProfile(
//   //                         name,
//   //                         isStudent: true,
//   //                         userId: studentId.isEmpty ? null : studentId,
//   //                       );
//   //                     },
//   //                     style: OutlinedButton.styleFrom(
//   //                       foregroundColor: Colors.blue.shade700,
//   //                       side: BorderSide(color: Colors.blue.shade700),
//   //                       minimumSize: const Size(0, 40),
//   //                       shape: RoundedRectangleBorder(
//   //                         borderRadius: BorderRadius.circular(8),
//   //                       ),
//   //                     ),
//   //                     child: const Text(
//   //                       'View Profile',
//   //                       style: TextStyle(fontSize: 14),
//   //                     ),
//   //                   ),
//   //                 ),
//   //                 const SizedBox(width: 8),
//   //                 SizedBox(
//   //                   width: 40,
//   //                   height: 40,
//   //                   child: ElevatedButton(
//   //                     onPressed: studentId.isEmpty
//   //                         ? null
//   //                         : () {
//   //                             _startChat(
//   //                               name,
//   //                               studentId,
//   //                               isStudent: true,
//   //                             );
//   //                           },
//   //                     style: ElevatedButton.styleFrom(
//   //                       backgroundColor: Colors.green.shade600,
//   //                       foregroundColor: Colors.white,
//   //                       padding: EdgeInsets.zero,
//   //                       shape: RoundedRectangleBorder(
//   //                         borderRadius: BorderRadius.circular(8),
//   //                       ),
//   //                     ),
//   //                     child: const Icon(Icons.chat, size: 18),
//   //                   ),
//   //                 ),
//   //               ],
//   //             ),
//   //           ],
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }
//   Widget _buildRecommendedStudentCard(Map<String, dynamic> rec) {
//     final name = (rec['name'] ?? 'Student').toString();

//     // 🔁 Backend uses "learnerId", not "studentId"
//     final learnerId = (rec['learnerId'] ?? rec['studentId'] ?? '').toString();

//     final city = (rec['city'] ?? 'Location not set').toString();

//     // Our rec docs contain gradeLevels, not "grade"
//     final gradeLevels =
//         (rec['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
//     final gradeText = gradeLevels.isEmpty
//         ? 'Student'
//         : 'Grades: ${gradeLevels.take(2).join(', ')}';

//     final age = rec['age'];
//     final gender = rec['sex']?.toString();
//     final subjects = (rec['subjects'] as List<dynamic>? ?? []).cast<String>();
//     final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
//     final score = (rec['score'] as num?)?.toDouble() ?? 0.0;
//     final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
//     final highlight =
//         reasons.isNotEmpty ? reasons.first : 'Matches your expertise';
//     final subjectsText = subjects.isEmpty
//         ? 'Interests not provided'
//         : 'Interests: ${subjects.take(3).join(', ')}';

//     return Container(
//       width: 260,
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.blue.shade100,
//                     child: Text(
//                       name.substring(0, 1),
//                       style: const TextStyle(
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           name,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           [
//                             gradeText,
//                             if (age is num) 'Age ${age.toInt()}',
//                             if (gender != null && gender.isNotEmpty) gender,
//                             city,
//                           ].where((e) => e.isNotEmpty).join(' • '),
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey.shade600,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       '$matchPercent% match',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.green.shade700,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 highlight,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 13,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 subjectsText,
//                 style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () {
//                         _viewProfile(
//                           name,
//                           isStudent: true,
//                           userId: learnerId.isEmpty ? null : learnerId,
//                         );
//                       },
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.blue.shade700,
//                         side: BorderSide(color: Colors.blue.shade700),
//                         minimumSize: const Size(0, 40),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Text(
//                         'View Profile',
//                         style: TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   SizedBox(
//                     width: 40,
//                     height: 40,
//                     child: ElevatedButton(
//                       onPressed: learnerId.isEmpty
//                           ? null
//                           : () {
//                               _startChat(
//                                 name,
//                                 learnerId,
//                                 isStudent: true,
//                               );
//                             },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green.shade600,
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.zero,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Icon(Icons.chat, size: 18),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Original tutor card method (used when user is student/parent)
//   Widget _buildTutorCard(
//     String name,
//     String subjects,
//     double rating,
//     String recommendation,
//     bool isAIRecommended,
//     double width,
//     int age,
//     String city,
//     double minPrice,
//   ) {
//     return Container(
//       width: width,
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.blue.shade100,
//                     child: Text(
//                       name.substring(0, 1),
//                       style: const TextStyle(
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           name,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         Text(
//                           '$age  • $city',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (isAIRecommended)
//                     Icon(
//                       Icons.auto_awesome,
//                       color: Colors.amber.shade600,
//                       size: 16,
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 subjects,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.blue.shade700,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Icon(Icons.star, color: Colors.amber.shade600, size: 16),
//                   const SizedBox(width: 4),
//                   Text(
//                     rating.toString(),
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const Spacer(),
//                   Text(
//                     'Birr$minPrice/hr',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               // Message and View Profile buttons
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () {
//                         _viewProfile(name, isStudent: false);
//                       },
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.blue.shade700,
//                         side: BorderSide(color: Colors.blue.shade700),
//                         minimumSize: const Size(0, 40),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Text(
//                         'View Profile',
//                         style: TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Container(
//                     width: 40,
//                     height: 40,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         _startChat(
//                           name,
//                           'tutor_fake_id_$name',
//                           isStudent: false,
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green.shade600,
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.zero,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Icon(Icons.chat, size: 18),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildRecommendationCards() {
//     if (_isLoadingRecommendations) {
//       return [
//         _buildRecommendationStatusCard(
//           child: const CircularProgressIndicator(strokeWidth: 2),
//         ),
//       ];
//     }

//     if (_recommendationsError != null) {
//       debugPrint('❌ _recommendationsError: $_recommendationsError');
//       return [
//         _buildRecommendationStatusCard(
//           message: 'Unable to load recommendations.\nTap to retry.\n\n'
//               'Details: $_recommendationsError',
//           onTap: _loadRecommendations,
//         ),
//       ];
//     }

//     if (_recommendedTutors.isEmpty) {
//       return [
//         _buildRecommendationStatusCard(
//           message: _userRole == 'tutor'
//               ? 'No personalized students yet.\nUpdate your profile to get matches.'
//               : 'No personalized tutors yet.\nUpdate your interests to get matches.',
//         ),
//       ];
//     }

//     final widgets = <Widget>[];
//     for (final rec in _recommendedTutors) {
//       if (widgets.isNotEmpty) {
//         widgets.add(const SizedBox(width: 16));
//       }
//       if (_userRole == 'tutor') {
//         widgets.add(_buildRecommendedStudentCard(rec));
//       } else {
//         widgets.add(_buildRecommendedTutorCard(rec));
//       }
//     }
//     return widgets;
//   }

//   Widget _buildRecommendationStatusCard({
//     String? message,
//     Widget? child,
//     VoidCallback? onTap,
//   }) {
//     final content = child ??
//         Text(
//           message ?? '',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 13,
//             color: Colors.blueGrey.shade700,
//             fontWeight: FontWeight.w500,
//           ),
//         );

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 260,
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.blue.shade50,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.blue.shade100),
//         ),
//         child: Center(child: content),
//       ),
//     );
//   }

//   Widget _buildRecommendedTutorCard(Map<String, dynamic> rec) {
//     final name = (rec['name'] ?? 'Tutor').toString();
//     final tutorId = (rec['tutorId'] ?? '').toString();
//     final city = (rec['city'] ?? 'Location not set').toString();
//     final profileImage = rec['profileImage']?.toString();
//     final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
//     final reason =
//         reasons.isNotEmpty ? reasons.first : 'Matches your learning goals';
//     final score = (rec['score'] as num?)?.toDouble() ?? 0.85;
//     final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
//     final theme = Theme.of(context);

//     return Container(
//       width: 320,
//       margin: const EdgeInsets.only(right: 16, bottom: 12),
//       decoration: BoxDecoration(
//         color: theme.brightness == Brightness.dark
//             ? const Color(0xFF10121C)
//             : Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black
//                 .withOpacity(theme.brightness == Brightness.dark ? 0.32 : 0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     color: theme.brightness == Brightness.dark
//                         ? const Color(0xFF1F2434)
//                         : const Color(0xFFEFEFEF),
//                     borderRadius: BorderRadius.circular(20),
//                     image: profileImage != null
//                         ? DecorationImage(
//                             image: NetworkImage(profileImage),
//                             fit: BoxFit.cover)
//                         : null,
//                   ),
//                   child: profileImage == null
//                       ? Icon(Icons.person,
//                           size: 36, color: Colors.grey.shade500)
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(name,
//                           style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w700,
//                               color: theme.colorScheme.onSurface)),
//                       const SizedBox(height: 2),
//                       Text(city,
//                           style: TextStyle(
//                               fontSize: 13,
//                               color: theme.colorScheme.onSurfaceVariant)),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               height: 6,
//                               decoration: BoxDecoration(
//                                 color: theme.brightness == Brightness.dark
//                                     ? Colors.grey.shade800
//                                     : const Color(0xFFE8EAEE),
//                                 borderRadius: BorderRadius.circular(100),
//                               ),
//                               child: FractionallySizedBox(
//                                 widthFactor: matchPercent / 100,
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFFF6AC17),
//                                     borderRadius: BorderRadius.circular(100),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             '$matchPercent% Match',
//                             style: const TextStyle(
//                                 color: Color(0xFFF6AC17),
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Text(
//               reason,
//               style: TextStyle(
//                   fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () =>
//                         _startChat(name, tutorId, isStudent: false),
//                     style: OutlinedButton.styleFrom(
//                       backgroundColor:
//                           theme.colorScheme.primary.withOpacity(0.18),
//                       foregroundColor: theme.colorScheme.primary,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                     ),
//                     child: const Text('Message',
//                         style: TextStyle(fontWeight: FontWeight.w600)),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => _viewProfile(name,
//                         isStudent: false,
//                         userId: tutorId.isEmpty ? null : tutorId),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: theme.colorScheme.primary,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                     ),
//                     child: const Text('View Profile',
//                         style: TextStyle(fontWeight: FontWeight.w600)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // UPDATED: Unified profile view method
//   void _viewProfile(
//     String name, {
//     bool isStudent = false,
//     String? userId,
//     Map<String, dynamic>? userData,
//   }) {
//     if (!isStudent && userId != null) {
//       InteractionLogger.log(
//         event: 'view_tutor_profile',
//         tutorId: userId,
//         data: {'source': 'home_profile'},
//       );
//     }
//     final bool isTutorViewingStudent = _userRole == 'tutor' && isStudent;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text('$name Profile'),
//                 if (userData?['verified'] == true && !isStudent) ...[
//                   const SizedBox(width: 8),
//                   Icon(Icons.verified, color: Colors.blue.shade700, size: 20),
//                 ],
//               ],
//             ),
//             if (!isStudent && userId != null) ...[
//               const SizedBox(height: 4),
//               RatingBadge(tutorId: userId!),
//             ],
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.blue.shade100, // CHANGED: Always blue
//                   backgroundImage: userData?['profileImage'] != null
//                       ? NetworkImage(userData!['profileImage'])
//                       : null,
//                   child: userData?['profileImage'] == null
//                       ? Text(
//                           name.substring(0, 1),
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue, // CHANGED: Always blue
//                           ),
//                         )
//                       : null,
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Basic Info (always shown)
//               Text(
//                 'Name: $name',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),

//               if (userData != null) ...[
//                 if (userData['age'] != null)
//                   Text('Age: ${userData['age']} years'),
//                 if (userData['age'] != null) const SizedBox(height: 8),
//                 if (userData['sex'] != null) Text('Gender: ${userData['sex']}'),
//                 if (userData['sex'] != null) const SizedBox(height: 8),
//                 if (userData['city'] != null) Text('City: ${userData['city']}'),
//                 if (userData['city'] != null) const SizedBox(height: 8),
//                 if (isStudent) ...[
//                   // Student-specific info
//                   if (userData['grade'] != null)
//                     Text('Grade: ${userData['grade']}'),
//                   if (userData['grade'] != null) const SizedBox(height: 8),

//                   if (userData['subjects'] != null &&
//                       (userData['subjects'] as List).isNotEmpty)
//                     Text(
//                       'Interested in: ${(userData['subjects'] as List).join(', ')}',
//                     ),
//                   if (userData['subjects'] != null &&
//                       (userData['subjects'] as List).isNotEmpty)
//                     const SizedBox(height: 8),

//                   if (userData['learningGoals'] != null)
//                     Text('Learning Goals: ${userData['learningGoals']}'),
//                   if (userData['learningGoals'] != null)
//                     const SizedBox(height: 8),
//                 ] else ...[
//                   // Tutor-specific info
//                   if (userData['qualification'] != null)
//                     Text('Qualification: ${userData['qualification']}'),
//                   if (userData['qualification'] != null)
//                     const SizedBox(height: 8),

//                   if (userData['subjects'] != null &&
//                       (userData['subjects'] as List).isNotEmpty)
//                     Text(
//                       'Subjects: ${(userData['subjects'] as List).join(', ')}',
//                     ),
//                   if (userData['subjects'] != null &&
//                       (userData['subjects'] as List).isNotEmpty)
//                     const SizedBox(height: 8),

//                   if (userData['gradeLevels'] != null &&
//                       (userData['gradeLevels'] as List).isNotEmpty)
//                     Text(
//                       'Grade Levels: ${(userData['gradeLevels'] as List).join(', ')}',
//                     ),
//                   if (userData['gradeLevels'] != null &&
//                       (userData['gradeLevels'] as List).isNotEmpty)
//                     const SizedBox(height: 8),

//                   if (userData['minPricePerHour'] != null)
//                     Text('Price: Birr${userData['minPricePerHour']}/hr'),
//                   if (userData['minPricePerHour'] != null)
//                     const SizedBox(height: 8),

//                   if (userData['hoursPerDay'] != null)
//                     Text('Hours per day: ${userData['hoursPerDay']}'),
//                   if (userData['hoursPerDay'] != null)
//                     const SizedBox(height: 8),

//                   if (userData['daysPerWeek'] != null)
//                     Text('Days per week: ${userData['daysPerWeek']}'),
//                   if (userData['daysPerWeek'] != null)
//                     const SizedBox(height: 8),

//                   if (userData['available'] != null)
//                     Text(
//                       'Available: ${userData['available']! ? 'Yes' : 'No'}',
//                       style: TextStyle(
//                         color:
//                             userData['available']! ? Colors.green : Colors.red,
//                       ),
//                     ),
//                   if (userData['available'] != null) const SizedBox(height: 8),
//                 ],
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _startChat(
//                 name,
//                 userId ?? '${isStudent ? 'student' : 'tutor'}_fake_id_$name',
//                 isStudent: isStudent,
//               );
//             },
//             child: const Text('Message'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchResults() {
//     // UPDATED: Create a new stream for each search query with a timeout - using your original logic
//     Stream<QuerySnapshot> searchStream() async* {
//       if (_searchQuery.isEmpty) {
//         // Return an empty stream instead of using QuerySnapshot.empty()
//         return;
//       }
//       try {
//         final targetRole = _getSearchTargetRole();
//         final collection = _getSearchTargetCollection();

//         final snapshot = await FirebaseFirestore.instance
//             .collection(collection)
//             .where('role', isEqualTo: targetRole)
//             .where('name', isGreaterThanOrEqualTo: _searchQuery)
//             .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
//             .limit(20)
//             .get();

//         yield snapshot;
//       } catch (e) {
//         debugPrint('🔴 Stream Error: $e');
//         yield* Stream<QuerySnapshot>.empty();
//       }
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: searchStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: Column(
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Searching...', style: TextStyle(color: Colors.grey)),
//               ],
//             ),
//           );
//         }

//         // Handle errors
//         if (snapshot.hasError) {
//           final error = snapshot.error.toString();
//           debugPrint('🔴 Search Error: $error');

//           // Check if it's an index error
//           if (error.contains('index') ||
//               error.contains('FAILED_PRECONDITION')) {
//             debugPrint('🔧 INDEX REQUIRED: $error');
//             return _buildIndexRequiredMessage();
//           }

//           return Center(
//             child: Column(
//               children: [
//                 Icon(Icons.error_outline, color: Colors.red, size: 48),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Search Error',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Please check your connection or try again',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () => setState(() {}), // Retry by rebuilding
//                   child: const Text('Retry Search'),
//                 ),
//               ],
//             ),
//           );
//         }

//         // Check if we have data and if it's empty
//         // If snapshot.hasData is false or docs is empty, show no results
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           debugPrint('✅ No results found for "$_searchQuery"');
//           return const Center(
//             child: Column(
//               children: [
//                 Icon(Icons.search_off, size: 48, color: Colors.grey),
//                 SizedBox(height: 16),
//                 Text('No results found', style: TextStyle(fontSize: 16)),
//                 SizedBox(height: 8),
//                 Text(
//                   'Try searching with a different name',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           );
//         }

//         final results = snapshot.data!.docs;
//         debugPrint(
//           '✅ SERVER-SIDE SEARCH: Found ${results.length} results for "$_searchQuery"',
//         );

//         return Column(
//           children: [
//             // Server-side indicator
//             Container(
//               padding: const EdgeInsets.all(12),
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.green.shade200),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.bolt, color: Colors.green.shade700, size: 20),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Fast Search Enabled',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.green.shade800,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Text(
//                           'Results from ${results.length} ${_userRole == 'tutor' ? 'students' : 'tutors'}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.green.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             ...results.map((doc) => _buildSearchResultCard(doc)).toList(),
//           ],
//         );
//       },
//     );
//   }

//   // Helper method for index required message - Your original method
//   Widget _buildIndexRequiredMessage() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.build, size: 64, color: Colors.orange.shade600),
//             const SizedBox(height: 24),
//             Text(
//               'Search Optimization Required',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'To enable fast search for 1000+ users, we need to create a search index.',
//               style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Quick Fix:',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       '1. Check your console for a Firebase index link\n2. Click the link to create the index\n3. Wait 2-5 minutes for it to build\n4. Search will become instant!',
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 // Fallback to local filtering temporarily
//                 setState(() {});
//               },
//               icon: Icon(Icons.search),
//               label: Text('Use Basic Search For Now'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange.shade600,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // UPDATED: Build individual search result card - dynamic based on role
//   Widget _buildSearchResultCard(DocumentSnapshot doc) {
//     final userData = doc.data() as Map<String, dynamic>;
//     final userId = doc.id;
//     final name = userData['name'] ?? 'Unknown';
//     final sex = userData['sex'] ?? '';
//     final age = userData['age'];
//     final city = userData['city'] ?? '';
//     final subjects =
//         (userData['subjects'] as List<dynamic>? ?? []).cast<String>();
//     final gradeLevels =
//         (userData['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
//     final qualification = userData['qualification']?.toString();
//     final available = userData['available'] == true;
//     final profileImage = userData['profileImage'];
//     final isVerified = userData['verified'] ?? false;

//     // Dynamic data based on role
//     final isStudent = _userRole ==
//         'tutor'; // If current user is tutor, then we're showing students
//     final displayInfo = isStudent
//         ? userData['grade'] ?? 'Student'
//         : 'Birr${userData['minPricePerHour'] ?? 0}/hr';

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.blue.shade100, // CHANGED: Always blue
//           backgroundImage:
//               profileImage != null ? NetworkImage(profileImage) : null,
//           child: profileImage == null
//               ? Text(
//                   name.substring(0, 1),
//                   style: TextStyle(
//                     color: Colors.blue, // CHANGED: Always blue
//                     fontWeight: FontWeight.bold,
//                   ),
//                 )
//               : null,
//         ),
//         title: Row(
//           children: [
//             Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
//             if (isVerified && !isStudent) ...[
//               const SizedBox(width: 4),
//               Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
//             ],
//             if (!isStudent) ...[
//               const SizedBox(width: 8),
//               RatingBadge(tutorId: userId),
//             ],
//           ],
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               [
//                 if (age is num) 'Age ${age.toInt()}',
//                 if (sex != '') sex,
//                 if (!isStudent && city.isNotEmpty) city,
//               ].join(' • '),
//             ),
//             if (!isStudent && subjects.isNotEmpty)
//               Text('Subjects: ${subjects.take(3).join(', ')}'),
//             if (!isStudent && gradeLevels.isNotEmpty)
//               Text('Grades: ${gradeLevels.take(3).join(', ')}'),
//             if (!isStudent && qualification != null && qualification.isNotEmpty)
//               Text('Qualification: $qualification'),
//             if (!isStudent)
//               Text(
//                 '${available ? 'Available' : 'Unavailable'} • $displayInfo',
//                 style: TextStyle(
//                   color:
//                       available ? Colors.green.shade700 : Colors.red.shade400,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             if (isStudent) Text('$sex • $displayInfo'),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: Icon(
//                 Icons.chat,
//                 color: Colors.green.shade600,
//               ), // CHANGED: Green to blue
//               onPressed: () {
//                 _startChat(name, userId, isStudent: isStudent);
//               },
//             ),
//             IconButton(
//               icon: Icon(
//                 Icons.visibility,
//                 color: Colors.blue.shade700,
//               ), // CHANGED: Always blue
//               onPressed: () {
//                 _viewProfile(
//                   name,
//                   isStudent: isStudent,
//                   userId: userId,
//                   userData: userData,
//                 );
//               },
//             ),
//           ],
//         ),
//         onTap: () {
//           if (!isStudent) {
//             InteractionLogger.log(
//               event: 'search_card_click',
//               tutorId: userId,
//               data: {'query': _searchQuery},
//             );
//           }
//           _viewProfile(
//             name,
//             isStudent: isStudent,
//             userId: userId,
//             userData: userData,
//           );
//         },
//       ),
//     );
//   }

//   // UPDATED: Unified chat method
//   void _startChat(
//     String personName,
//     String personId, {
//     bool isStudent = false,
//   }) {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return;

//     final messageProvider = Provider.of<MessageProvider>(
//       context,
//       listen: false,
//     );

//     // Determine initial message based on role
//     final initialMessage = _userRole == 'tutor'
//         ? "Hello! I'm interested in tutoring you."
//         : "Hello! I'm interested in your tutoring services.";

//     FirebaseFirestore.instance
//         .collection('users')
//         .doc(currentUser.uid)
//         .get()
//         .then((doc) {
//       if (doc.exists) {
//         final data = doc.data();
//       }

//       final String senderName;
//       if (doc.exists && doc.data()?['name'] != null) {
//         senderName = doc.data()!['name'];
//       } else {
//         senderName = _userName ?? (_userRole == 'tutor' ? 'Tutor' : 'Student');
//       }

//       if (!isStudent) {
//         InteractionLogger.log(
//           event: 'start_chat',
//           tutorId: personId,
//           data: {'source': 'home'},
//         );
//       }

//       messageProvider
//           .sendMessage(
//         senderId: currentUser.uid,
//         senderName: senderName,
//         receiverId: personId,
//         receiverName: personName,
//         content: initialMessage,
//       )
//           .then((_) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ChatScreen(
//               receiverId: personId,
//               receiverName: personName,
//             ),
//           ),
//         );
//       }).catchError((error) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to start chat: $error')),
//         );
//       });
//     }).catchError((error) {});
//   }

//   Widget _buildTopRatedList() {
//     final targetRole = _userRole == 'tutor' ? 'student' : 'tutor';

//     // UPDATED: Proper Firestore query construction
//     Query query = FirebaseFirestore.instance
//         .collection('users')
//         .where('role', isEqualTo: targetRole)
//         .limit(3);

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Text(
//               _userRole == 'tutor'
//                   ? 'No students available.'
//                   : 'No tutors available.',
//             ),
//           );
//         }

//         final users = snapshot.data!.docs;

//         return Column(
//           children: users.map((doc) {
//             final user = doc.data() as Map<String, dynamic>;
//             final name = user['name'] ?? 'Unknown';
//             final sex = user['sex'] ?? '';
//             final profileImage = user['profileImage'];
//             final isVerified = user['verified'] ?? false;
//             final isStudent = targetRole == 'student';

//             final displayInfo = isStudent
//                 ? user['grade'] ?? 'Student'
//                 : 'Birr${user['minPricePerHour'] ?? 0}/hr';

//             return _buildUserListItem(
//               name,
//               sex,
//               displayInfo,
//               doc.id,
//               profileImage,
//               isVerified,
//               isStudent: isStudent,
//             );
//           }).toList(),
//         );
//       },
//     );
//   }

//   // UPDATED: Build user list item (unified for both tutors and students)
//   Widget _buildUserListItem(
//     String name,
//     String sex,
//     String displayInfo,
//     String userId,
//     String? profileImage,
//     bool isVerified, {
//     bool isStudent = false,
//   }) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.blue.shade100, // CHANGED: Always blue
//           backgroundImage:
//               profileImage != null ? NetworkImage(profileImage) : null,
//           child: profileImage == null
//               ? Text(
//                   name.substring(0, 1),
//                   style: TextStyle(
//                     color: Colors.blue, // CHANGED: Always blue
//                     fontWeight: FontWeight.bold,
//                   ),
//                 )
//               : null,
//         ),
//         title: Row(
//           children: [
//             Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
//             if (isVerified && !isStudent) ...[
//               const SizedBox(width: 4),
//               Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
//             ],
//           ],
//         ),
//         subtitle: Text('$sex • $displayInfo'),
//         trailing: IconButton(
//           icon: Icon(
//             Icons.chat,
//             color: Colors.green.shade600,
//             size: 20,
//           ), // CHANGED: Green to blue
//           onPressed: () {
//             _startChat(name, userId, isStudent: isStudent);
//           },
//         ),
//         onTap: () {
//           FirebaseFirestore.instance.collection('users').doc(userId).get().then(
//             (doc) {
//               if (doc.exists) {
//                 _viewProfile(
//                   name,
//                   isStudent: isStudent,
//                   userId: userId,
//                   userData: doc.data() as Map<String, dynamic>,
//                 );
//               }
//             },
//           );
//         },
//       ),
//     );
//   }

//   // Function to change theme
//   void _changeTheme(bool isDarkMode) {
//     setState(() {
//       ThemeData newTheme = isDarkMode
//           ? ThemeData.dark().copyWith(
//               primaryColor: Colors.blue.shade700,
//               scaffoldBackgroundColor: Colors.grey.shade900,
//               cardColor: Colors.grey.shade800,
//               textTheme: ThemeData.dark().textTheme.apply(
//                     bodyColor: Colors.white,
//                     displayColor: Colors.white,
//                   ),
//               iconTheme: const IconThemeData(color: Colors.white),
//             )
//           : ThemeData.light().copyWith(
//               primaryColor: Colors.blue.shade700,
//               scaffoldBackgroundColor: Colors.grey.shade50,
//               cardColor: Colors.white,
//               textTheme: ThemeData.light().textTheme.apply(
//                     bodyColor: Colors.black87,
//                     displayColor: Colors.black87,
//                   ),
//               iconTheme: const IconThemeData(color: Colors.black87),
//             );
//       (context as Element).markNeedsBuild();
//     });
//   }

//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(_userRole == 'tutor' ? 'Filter Students' : 'Filter Tutors'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView(
//             shrinkWrap: true,
//             children: [
//               const Text(
//                 'Subject',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               DropdownButtonFormField(
//                 value: _selectedSubject,
//                 items: _subjects
//                     .map(
//                       (subject) => DropdownMenuItem(
//                         value: subject,
//                         child: Text(subject),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: (value) => setState(() => _selectedSubject = value!),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Grade Level',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               DropdownButtonFormField(
//                 value: _selectedGrade,
//                 items: _grades
//                     .map(
//                       (grade) =>
//                           DropdownMenuItem(value: grade, child: Text(grade)),
//                     )
//                     .toList(),
//                 onChanged: (value) => setState(() => _selectedGrade = value!),
//               ),
//               const SizedBox(height: 16),
//               if (_userRole != 'tutor') ...[
//                 const Text(
//                   'Max Price per Hour',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 Slider(
//                   value: _priceRange,
//                   min: 100,
//                   max: 1000,
//                   divisions: 9,
//                   label: 'Birr$_priceRange',
//                   onChanged: (value) => setState(() => _priceRange = value),
//                 ),
//                 Text('Birr$_priceRange', textAlign: TextAlign.center),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: _onlyVerified,
//                       onChanged: (value) =>
//                           setState(() => _onlyVerified = value!),
//                     ),
//                     const Text('Verified Tutors Only'),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Apply Filters'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessagesTab() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

//     if (currentUser == null) {
//       return const Center(child: Text('Please login to view messages'));
//     }

//     return StreamBuilder<List<Message>>(
//       stream: Provider.of<MessageProvider>(
//         context,
//       ).getConversations(currentUser.uid),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.chat_bubble_outline,
//                         color: Colors.blue.shade700,
//                       ),
//                       const SizedBox(width: 12),
//                       const Expanded(
//                         child: Text(
//                           'Your conversations will appear here',
//                           style: TextStyle(fontSize: 16, color: Colors.black87),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         final conversations = snapshot.data!;

//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: conversations.length,
//           itemBuilder: (context, index) {
//             final conversation = conversations[index];

//             final isCurrentUserSender =
//                 conversation.senderId == currentUser.uid;
//             final otherPersonName = isCurrentUserSender
//                 ? conversation.receiverName
//                 : conversation.senderName;
//             final otherPersonId = isCurrentUserSender
//                 ? conversation.receiverId
//                 : conversation.senderId;

//             final isUnread = conversation.receiverId == currentUser.uid &&
//                 !conversation.isRead;

//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: Colors.blue.shade100,
//                   child: Text(
//                     otherPersonName.substring(0, 1).toUpperCase(),
//                     style: TextStyle(
//                       color: Colors.blue.shade700,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 title: Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         otherPersonName,
//                         style: TextStyle(
//                           fontWeight:
//                               isUnread ? FontWeight.bold : FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     if (isUnread)
//                       Container(
//                         width: 8,
//                         height: 8,
//                         decoration: const BoxDecoration(
//                           color: Colors.blue,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                   ],
//                 ),
//                 subtitle: Text(
//                   conversation.content,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 trailing: Text(
//                   _formatTime(conversation.timestamp),
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ChatScreen(
//                         receiverId: otherPersonId,
//                         receiverName: otherPersonName,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   String _formatTime(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }

//   Widget _buildMessageItem(String name, String message, String time) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.blue.shade100,
//           child: Text(name.substring(0, 1)),
//         ),
//         title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
//         subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
//         trailing: Text(
//           time,
//           style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//         ),
//       ),
//     );
//   }

//   Widget _buildNotificationsTab() {
//     // Get the current user from Firebase Auth
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

//     if (currentUser == null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red),
//             SizedBox(height: 16),
//             Text('Please login to view notifications'),
//           ],
//         ),
//       );
//     }

//     String currentUserId = currentUser.uid; // ✅ REAL USER ID

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           // Header banner
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.notifications_none, color: Colors.green.shade700),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     _userRole == 'tutor'
//                         ? 'Stay updated with your teaching activities'
//                         : 'Stay updated with your learning journey',
//                     style: const TextStyle(fontSize: 16, color: Colors.black87),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Real notifications from Firestore
//           Expanded(
//             child: StreamBuilder<List<NotificationModel>>(
//               stream: Provider.of<NotificationProvider>(
//                 context,
//                 listen: true,
//               ).getUserNotifications(currentUserId),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 final notifications = snapshot.data ?? [];

//                 if (notifications.isEmpty) {
//                   return ui.EmptyState(
//                     icon: Icons.notifications_off,
//                     title: 'No notifications yet',
//                     message: 'Your notifications will appear here',
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: notifications.length,
//                   itemBuilder: (context, index) {
//                     final notification = notifications[index];
//                     return _buildNotificationItem(notification);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationItem(NotificationModel notification) {
//     // Get appropriate icon based on notification type
//     IconData icon;
//     Color iconColor;

//     switch (notification.type) {
//       case 'meeting_request':
//         icon = Icons.person_add;
//         iconColor = Colors.blue.shade700;
//         break;
//       case 'meeting_accepted':
//         icon = Icons.check_circle;
//         iconColor = Colors.green.shade700;
//         break;
//       case 'meeting_declined':
//         icon = Icons.cancel;
//         iconColor = Colors.red.shade700;
//         break;
//       case 'meeting_reminder':
//         icon = Icons.access_time;
//         iconColor = Colors.orange.shade700;
//         break;
//       case 'verification_required':
//         icon = Icons.verified;
//         iconColor = Colors.purple.shade700;
//         break;
//       default:
//         icon = Icons.notifications;
//         iconColor = Colors.grey.shade700;
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: iconColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         title: Text(
//           notification.title,
//           style: TextStyle(
//             fontWeight:
//                 notification.isRead ? FontWeight.normal : FontWeight.w600,
//             color: notification.isRead ? Colors.grey : Colors.black,
//           ),
//         ),
//         subtitle: Text(
//           notification.body,
//           style: TextStyle(
//             color: notification.isRead ? Colors.grey : Colors.black87,
//           ),
//         ),
//         trailing: notification.isRead
//             ? null
//             : Container(
//                 width: 8,
//                 height: 8,
//                 decoration: const BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//         onTap: () {
//           // Mark as read when tapped
//           Provider.of<NotificationProvider>(
//             context,
//             listen: false,
//           ).markAsRead(notification.id);

//           // Handle notification action based on type
//           _handleNotificationTap(notification);
//         },
//       ),
//     );
//   }

//   Widget _buildEmptyNotifications() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
//           const SizedBox(height: 16),
//           Text(
//             'No notifications yet',
//             style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Your notifications will appear here',
//             style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleNotificationTap(NotificationModel notification) {
//     // Handle different notification types
//     switch (notification.type) {
//       case 'meeting_request':
//         // Navigate to meeting requests screen

//         break;
//       case 'meeting_accepted':
//         // Navigate to meeting details

//         break;
//       case 'meeting_reminder':
//         // Navigate to upcoming session

//         break;
//       // Add more cases for other notification types
//       default:
//     }
//   }

//   Widget _buildProfileTab() {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundColor: Colors.blue.shade100,
//                     backgroundImage: _profileImage != null
//                         ? NetworkImage(_profileImage!)
//                         : null,
//                     child: _profileImage == null
//                         ? Icon(
//                             Icons.person,
//                             size: 40,
//                             color: Colors.blue.shade700,
//                           )
//                         : null,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     _userName ?? 'User Name',
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     _userRole?.toUpperCase() ?? 'STUDENT',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.blue.shade700,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       _buildProfileStat(
//                         _userRole == 'tutor' ? 'Students' : 'Tutors',
//                         '5',
//                       ),
//                       _buildProfileStat('Sessions', '12'),
//                       _buildProfileStat('Rating', '4.8'),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               children: [
//                 _buildProfileOption(
//                   'Edit Profile',
//                   Icons.edit_outlined,
//                   onTap: () {
//                     final role = _userRole ?? 'student';
//                     switch (role) {
//                       case 'tutor':
//                         Navigator.pushNamed(context, '/tutor-info');
//                         break;
//                       case 'parent':
//                         Navigator.pushNamed(context, '/parent-info');
//                         break;
//                       case 'student':
//                       default:
//                         Navigator.pushNamed(context, '/student-info');
//                     }
//                   },
//                 ),
//                 _buildProfileOption('Settings', Icons.settings_outlined),
//                 _buildProfileOption('Help & Support', Icons.help_outline),
//                 _buildProfileOption(
//                   'Logout',
//                   Icons.logout,
//                   isLogout: true,
//                   onTap: () async {
//                     await authProvider.logout();
//                     Navigator.pushReplacementNamed(context, '/');
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileStat(String label, String value) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//         ),
//       ],
//     );
//   }

//   Widget _buildProfileOption(
//     String title,
//     IconData icon, {
//     bool isLogout = false,
//     VoidCallback? onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue.shade700),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isLogout ? Colors.red : Colors.black87,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: onTap,
//     );
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   Stream<int> _getUnreadMessageCount() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return Stream.value(0);

//     return FirebaseFirestore.instance
//         .collection('messages')
//         .where('receiverId', isEqualTo: currentUser.uid)
//         .where('isRead', isEqualTo: false)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length)
//         .handleError((error) {
//       return 0;
//     });
//   }

//   // Get unread notifications count without marking them read
//   Stream<int> _getUnreadNotificationCount() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return Stream.value(0);

//     return FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: currentUser.uid)
//         .where('isRead', isEqualTo: false)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length)
//         .handleError((error) {
//       return 0;
//     });
//   }

//   // Get relationships attention count (badge for Relationships tab)
//   // - Tutors: pending meeting requests to approve
//   // - Students/Parents: approved meetings waiting for student verification
//   Stream<int> _getRelationshipAttentionCount() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return Stream.value(0);

//     final uid = currentUser.uid;
//     if (_userRole == 'tutor') {
//       return FirebaseFirestore.instance
//           .collection('meetingRequests')
//           .where('toUserId', isEqualTo: uid)
//           .where('status', isEqualTo: 'pending')
//           .snapshots()
//           .map((s) => s.docs.length)
//           .handleError((error) {
//         return 0;
//       });
//     } else {
//       return FirebaseFirestore.instance
//           .collection('meetingRequests')
//           .where('fromUserId', isEqualTo: uid)
//           .where('status', isEqualTo: 'approved')
//           .where('studentVerifiedMeeting', isEqualTo: false)
//           .snapshots()
//           .map((s) => s.docs.length)
//           .handleError((error) {
//         return 0;
//       });
//     }
//   }

//   // NEW: Mark all messages as read when Messages tab is clicked
//   Future<void> _markAllMessagesAsRead() async {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return;

//     try {
//       final query = await FirebaseFirestore.instance
//           .collection('messages')
//           .where('receiverId', isEqualTo: currentUser.uid)
//           .where('isRead', isEqualTo: false)
//           .get();

//       final batch = FirebaseFirestore.instance.batch();
//       for (final doc in query.docs) {
//         batch.update(doc.reference, {'isRead': true});
//       }
//       if (query.docs.isNotEmpty) {
//         await batch.commit();
//       }
//     } catch (error) {}
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

//     return MaterialApp(
//       theme: AppTheme.light,
//       darkTheme: AppTheme.dark,
//       themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
//       home: Builder(
//         builder: (context) => Scaffold(
//           appBar: AppBar(
//             title: Text(_getMainTitle()),
//             backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
//             elevation: 0,
//             automaticallyImplyLeading: false,
//           ),
//           body: IndexedStack(
//             index: _selectedIndex,
//             children: [
//               _buildHomeTab(), // index 0
//               _buildMessagesTab(), // index 1
//               _buildNotificationsTab(), // index 2
//               RelationshipsScreen(), // index 3
//               _buildProfileTab(), // index 4
//             ],
//           ),
//           bottomNavigationBar: StreamBuilder<int>(
//             stream: _getUnreadMessageCount(),
//             builder: (context, msgSnapshot) {
//               final unreadMsgCount = msgSnapshot.data ?? 0;

//               return StreamBuilder<int>(
//                 stream: _getUnreadNotificationCount(),
//                 builder: (context, notifSnapshot) {
//                   final unreadNotifCount = notifSnapshot.data ?? 0;
//                   final effectiveNotifCount =
//                       _selectedIndex == 2 ? 0 : unreadNotifCount;

//                   return StreamBuilder<int>(
//                     stream: _getRelationshipAttentionCount(),
//                     builder: (context, relSnapshot) {
//                       final relCount = relSnapshot.data ?? 0;
//                       final effectiveRelCount =
//                           _selectedIndex == 3 ? 0 : relCount;

//                       return Container(
//                         decoration: BoxDecoration(
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.2),
//                               blurRadius: 10,
//                               offset: const Offset(0, -2),
//                             ),
//                           ],
//                         ),
//                         child: BottomNavigationBar(
//                           currentIndex: _selectedIndex,
//                           onTap: (index) {
//                             // FIXED: Only change tab, don't mark messages as read
//                             setState(() => _selectedIndex = index);
//                           },
//                           type: BottomNavigationBarType.fixed,
//                           backgroundColor: Colors.white,
//                           selectedItemColor: Colors.blue.shade700,
//                           unselectedItemColor: Colors.grey.shade600,
//                           selectedLabelStyle: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                           ),
//                           items: [
//                             const BottomNavigationBarItem(
//                               icon: Icon(Icons.home_outlined),
//                               activeIcon: Icon(Icons.home),
//                               label: 'Home',
//                             ),
//                             BottomNavigationBarItem(
//                               icon: Stack(
//                                 children: [
//                                   const Icon(Icons.chat_bubble_outline),
//                                   if (unreadMsgCount > 0)
//                                     Positioned(
//                                       right: 0,
//                                       top: 0,
//                                       child: Container(
//                                         padding: const EdgeInsets.all(2),
//                                         decoration: const BoxDecoration(
//                                           color: Colors.red,
//                                           shape: BoxShape.circle,
//                                         ),
//                                         constraints: const BoxConstraints(
//                                           minWidth: 16,
//                                           minHeight: 16,
//                                         ),
//                                         child: Text(
//                                           unreadMsgCount > 99
//                                               ? '99+'
//                                               : unreadMsgCount.toString(),
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 8,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                               activeIcon: Stack(
//                                 children: [
//                                   const Icon(Icons.chat),
//                                   if (unreadMsgCount > 0)
//                                     Positioned(
//                                       right: 0,
//                                       top: 0,
//                                       child: Container(
//                                         padding: const EdgeInsets.all(2),
//                                         decoration: const BoxDecoration(
//                                           color: Colors.red,
//                                           shape: BoxShape.circle,
//                                         ),
//                                         constraints: const BoxConstraints(
//                                           minWidth: 16,
//                                           minHeight: 16,
//                                         ),
//                                         child: Text(
//                                           unreadMsgCount > 99
//                                               ? '99+'
//                                               : unreadMsgCount.toString(),
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 8,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                               label: 'Messages',
//                             ),
//                             BottomNavigationBarItem(
//                               icon: Stack(
//                                 children: [
//                                   const Icon(Icons.notifications_outlined),
//                                   if (effectiveNotifCount > 0)
//                                     Positioned(
//                                       right: 0,
//                                       top: 0,
//                                       child: Container(
//                                         padding: const EdgeInsets.all(2),
//                                         decoration: const BoxDecoration(
//                                           color: Colors.red,
//                                           shape: BoxShape.circle,
//                                         ),
//                                         constraints: const BoxConstraints(
//                                           minWidth: 16,
//                                           minHeight: 16,
//                                         ),
//                                         child: Text(
//                                           effectiveNotifCount > 99
//                                               ? '99+'
//                                               : effectiveNotifCount.toString(),
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 8,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                               activeIcon: const Icon(Icons.notifications),
//                               label: 'Notifications',
//                             ),
//                             BottomNavigationBarItem(
//                               icon: Stack(
//                                 children: [
//                                   const Icon(Icons.group_outlined),
//                                   if (effectiveRelCount > 0)
//                                     Positioned(
//                                       right: 0,
//                                       top: 0,
//                                       child: Container(
//                                         padding: const EdgeInsets.all(2),
//                                         decoration: const BoxDecoration(
//                                           color: Colors.red,
//                                           shape: BoxShape.circle,
//                                         ),
//                                         constraints: const BoxConstraints(
//                                           minWidth: 16,
//                                           minHeight: 16,
//                                         ),
//                                         child: Text(
//                                           effectiveRelCount > 99
//                                               ? '99+'
//                                               : effectiveRelCount.toString(),
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 8,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                               activeIcon: const Icon(Icons.group),
//                               label: 'Relationships',
//                             ),
//                             const BottomNavigationBarItem(
//                               icon: Icon(Icons.person_outlined),
//                               activeIcon: Icon(Icons.person),
//                               label: 'Profile',
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/relationships_screen.dart';
import '../services/interaction_logger.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/empty_state.dart' as ui;
import '../widgets/ui/rating_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userName;
  String? _userRole;
  String? _profileImage;
  bool _isDarkMode = false;

  // Search filters
  String _selectedSubject = 'All Subjects';
  String _selectedGrade = 'All Grades';
  double _priceRange = 500;
  bool _onlyVerified = true;
  String _searchQuery = '';

  bool _isLoadingRecommendations = false;
  String? _recommendationsError;
  List<Map<String, dynamic>> _recommendedTutors = [];

  final List<String> _subjects = [
    'All Subjects',
    'Mathematics',
    'English',
    'Amharic',
    'Tigrigna',
    'Physics',
    'Chemistry',
    'Biology',
    'ICT',
  ];

  final List<String> _grades = [
    'All Grades',
    'KG',
    '1–4',
    '5–6',
    '7–8',
    '9–10',
    '11–12',
  ];

  // Debounce timer for search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecommendations();
    _searchQuery = '';
  }

  Future<void> _loadUserData() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userRole = doc.data()?['role'];
          _userName = doc.data()?['name'];
          _profileImage = doc.data()?['profileImage'];
        });
      } else {
        doc = await FirebaseFirestore.instance
            .collection('tutors')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userRole = 'tutor';
            _userName = doc.data()?['name'];
            _profileImage = doc.data()?['profileImage'];
          });
        }
      }
    }
  }

  /// Load recommendations (now also on web – no skipping on Chrome).
  Future<void> _loadRecommendations() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔥 _loadRecommendations: no current user');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationsError = null;
    });

    try {
      debugPrint('🔍 Loading recommendations for uid=${user.uid}');

      // 1️⃣ Get role (and update _userRole if it was null)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      final role = (userDoc.data()?['role'] as String?) ?? 'student';
      if (_userRole == null) {
        setState(() {
          _userRole = role;
        });
      }

      // 2️⃣ Pick the right collection
      final String recCollection =
          role == 'tutor' ? 'tutor_recommendations' : 'recommendations';

      debugPrint('📚 Using rec collection: $recCollection for role=$role');

      // 3️⃣ Fetch the recommendation doc
      final doc = await FirebaseFirestore.instance
          .collection(recCollection)
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      debugPrint('📄 $recCollection/${user.uid} exists: ${doc.exists}');
      debugPrint('📄 raw data: ${doc.data()}');

      if (!doc.exists || doc.data() == null) {
        if (!mounted) return;
        setState(() {
          _recommendedTutors = [];
          _recommendationsError = null; // "no personalized X yet"
        });
        return;
      }

      final data = doc.data()!;
      final rawItemsDynamic = data['items'];

      if (rawItemsDynamic == null) {
        debugPrint('⚠️ "items" field missing in $recCollection doc.');
        if (!mounted) return;
        setState(() {
          _recommendedTutors = [];
          _recommendationsError = null;
        });
        return;
      }

      if (rawItemsDynamic is! List) {
        debugPrint(
            '❌ "items" is not a List. Got: ${rawItemsDynamic.runtimeType}');
        if (!mounted) return;
        setState(() {
          _recommendedTutors = [];
          _recommendationsError =
              'Invalid recommendations format (items is not a list)';
        });
        return;
      }

      final rawItems = rawItemsDynamic.cast<dynamic>();
      debugPrint('✅ items length = ${rawItems.length}');

      final items = <Map<String, dynamic>>[];
      for (final item in rawItems) {
        if (item is Map) {
          items.add(Map<String, dynamic>.from(item as Map));
        } else {
          debugPrint('⚠️ Skipping non-map recommendation item: $item');
        }
      }

      debugPrint('✅ Parsed ${items.length} recommendation maps');

      if (!mounted) return;
      setState(() {
        _recommendedTutors = items;
        _recommendationsError = null;
      });
    } catch (e, st) {
      debugPrint('❌ Error loading recommendations: $e');
      debugPrint('STACK:\n$st');

      if (!mounted) return;
      setState(() {
        _recommendedTutors = [];
        _recommendationsError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingRecommendations = false);
    }
  }

  // Role-based text helpers
  String _getWelcomeMessage() {
    switch (_userRole) {
      case 'tutor':
        return 'Find learners that match your expertise';
      case 'parent':
        return 'Find the perfect tutor for your child';
      case 'student':
      default:
        return 'Find the perfect tutor for your needs';
    }
  }

  String _getMainTitle() {
    switch (_userRole) {
      case 'tutor':
        return 'Find Learners';
      case 'parent':
      case 'student':
      default:
        return 'Find Tutors';
    }
  }

  String _getSearchHintText() {
    switch (_userRole) {
      case 'tutor':
        return 'Search students by name...';
      case 'parent':
      case 'student':
      default:
        return 'Search for tutors by name...';
    }
  }

  String _getSearchTargetRole() {
    switch (_userRole) {
      case 'tutor':
        return 'student'; // Tutors search for students
      case 'parent':
        return 'tutor'; // Parents search for tutors
      case 'student':
      default:
        return 'tutor'; // Students search for tutors
    }
  }

  String _getSearchTargetCollection() {
    switch (_userRole) {
      case 'tutor':
        return 'users'; // Tutors search in users collection for students
      case 'parent':
      case 'student':
      default:
        return 'users'; // Students/parents search in users collection for tutors
    }
  }

  String _getAIRecommendationTitle() {
    switch (_userRole) {
      case 'tutor':
        return 'AI Recommended Students';
      case 'parent':
      case 'student':
      default:
        return 'AI Recommended Tutors';
    }
  }

  String _getAIRecommendationSubtitle() {
    switch (_userRole) {
      case 'tutor':
        return 'Based on your expertise and teaching preferences';
      case 'parent':
      case 'student':
      default:
        return 'Based on your profile and learning preferences';
    }
  }

  String _getTopRatedTitle() {
    switch (_userRole) {
      case 'tutor':
        return 'Top Rated Students';
      case 'parent':
      case 'student':
      default:
        return 'Top Rated Tutors';
    }
  }

  // HOME TAB
  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with theme toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${_userName ?? 'there'}! 👋",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getWelcomeMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                    _changeTheme(_isDarkMode);
                  },
                  icon: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF101922)
                      : const Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F2434)
                            : const Color(0xFFEFEFEF),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) {
                            _debounce!.cancel();
                          }
                          _debounce =
                              Timer(const Duration(milliseconds: 500), () {
                            setState(() {
                              _searchQuery = value;
                            });
                          });
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: _getSearchHintText(),
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Search Results Section
            if (_searchQuery.isNotEmpty) ...[
              Text(
                'Search Results for "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildSearchResults(),
              const SizedBox(height: 30),
            ],

            // AI Recommended Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getAIRecommendationTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI Powered',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getAIRecommendationSubtitle(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // AI Recommended Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 4),
                  ..._buildRecommendationCards(),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            if (_userRole == 'student' || _userRole == 'parent') ...[
              const SizedBox(height: 30),
              Text(
                _getTopRatedTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTopRatedList(),
            ],
          ],
        ),
      ),
    );
  }

  // Recommendation card for tutors viewing students (tutor_recommendations)
  Widget _buildRecommendedStudentCard(Map<String, dynamic> rec) {
    final name = (rec['name'] ?? 'Student').toString();
    final learnerId = (rec['learnerId'] ?? rec['studentId'] ?? '').toString();
    final city = (rec['city'] ?? 'Location not set').toString();

    final gradeLevels =
        (rec['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
    final gradeText = gradeLevels.isEmpty
        ? 'Student'
        : 'Grades: ${gradeLevels.take(2).join(', ')}';

    final age = rec['age'];
    final gender = rec['sex']?.toString();
    final subjects = (rec['subjects'] as List<dynamic>? ?? []).cast<String>();
    final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
    final score = (rec['score'] as num?)?.toDouble() ?? 0.0;
    final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
    final highlight =
        reasons.isNotEmpty ? reasons.first : 'Matches your expertise';
    final subjectsText = subjects.isEmpty
        ? 'Interests not provided'
        : 'Interests: ${subjects.take(3).join(', ')}';

    return SizedBox(
      width: 260,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            gradeText,
                            if (age is num) 'Age ${age.toInt()}',
                            if (gender != null && gender.isNotEmpty) gender,
                            city,
                          ].where((e) => e.isNotEmpty).join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$matchPercent% match',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                highlight,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subjectsText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _viewProfile(
                          name,
                          isStudent: true,
                          userId: learnerId.isEmpty ? null : learnerId,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: learnerId.isEmpty
                          ? null
                          : () {
                              _startChat(
                                name,
                                learnerId,
                                isStudent: true,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.chat, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Legacy tutor card (used in some places)
  Widget _buildTutorCard(
    String name,
    String subjects,
    double rating,
    String recommendation,
    bool isAIRecommended,
    double width,
    int age,
    String city,
    double minPrice,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$age  • $city',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAIRecommended)
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.amber.shade600,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subjects,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Birr$minPrice/hr',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _viewProfile(name, isStudent: false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        _startChat(
                          name,
                          'tutor_fake_id_$name',
                          isStudent: false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.chat, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecommendationCards() {
    if (_isLoadingRecommendations) {
      return [
        _buildRecommendationStatusCard(
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ];
    }

    if (_recommendationsError != null) {
      debugPrint('❌ _recommendationsError: $_recommendationsError');
      return [
        _buildRecommendationStatusCard(
          message: 'Unable to load recommendations.\nTap to retry.\n\n'
              'Details: $_recommendationsError',
          onTap: _loadRecommendations,
        ),
      ];
    }

    if (_recommendedTutors.isEmpty) {
      return [
        _buildRecommendationStatusCard(
          message: _userRole == 'tutor'
              ? 'No personalized students yet.\nUpdate your profile to get matches.'
              : 'No personalized tutors yet.\nUpdate your interests to get matches.',
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final rec in _recommendedTutors) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(width: 16));
      }
      if (_userRole == 'tutor') {
        widgets.add(_buildRecommendedStudentCard(rec));
      } else {
        widgets.add(_buildRecommendedTutorCard(rec));
      }
    }
    return widgets;
  }

  Widget _buildRecommendationStatusCard({
    String? message,
    Widget? child,
    VoidCallback? onTap,
  }) {
    final content = child ??
        Text(
          message ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w500,
          ),
        );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Center(child: content),
      ),
    );
  }

  Widget _buildRecommendedTutorCard(Map<String, dynamic> rec) {
    final name = (rec['name'] ?? 'Tutor').toString();
    final tutorId = (rec['tutorId'] ?? '').toString();
    final city = (rec['city'] ?? 'Location not set').toString();
    final profileImage = rec['profileImage']?.toString();
    final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
    final reason =
        reasons.isNotEmpty ? reasons.first : 'Matches your learning goals';
    final score = (rec['score'] as num?)?.toDouble() ?? 0.85;
    final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
    final theme = Theme.of(context);

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF10121C)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(theme.brightness == Brightness.dark ? 0.32 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1F2434)
                        : const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(20),
                    image: profileImage != null
                        ? DecorationImage(
                            image: NetworkImage(profileImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profileImage == null
                      ? Icon(Icons.person,
                          size: 36, color: Colors.grey.shade500)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey.shade800
                                    : const Color(0xFFE8EAEE),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: matchPercent / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6AC17),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$matchPercent% Match',
                            style: const TextStyle(
                              color: Color(0xFFF6AC17),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              reason,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _startChat(name, tutorId, isStudent: false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.18),
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Message',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewProfile(
                      name,
                      isStudent: false,
                      userId: tutorId.isEmpty ? null : tutorId,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Unified profile view dialog
  void _viewProfile(
    String name, {
    bool isStudent = false,
    String? userId,
    Map<String, dynamic>? userData,
  }) {
    if (!isStudent && userId != null) {
      InteractionLogger.log(
        event: 'view_tutor_profile',
        tutorId: userId,
        data: {'source': 'home_profile'},
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$name Profile'),
                if (userData?['verified'] == true && !isStudent) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.verified, color: Colors.blue.shade700, size: 20),
                ],
              ],
            ),
            if (!isStudent && userId != null) ...[
              const SizedBox(height: 4),
              RatingBadge(tutorId: userId),
            ],
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: userData?['profileImage'] != null
                      ? NetworkImage(userData!['profileImage'])
                      : null,
                  child: userData?['profileImage'] == null
                      ? Text(
                          name.substring(0, 1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Name: $name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (userData != null) ...[
                if (userData['age'] != null)
                  Text('Age: ${userData['age']} years'),
                if (userData['age'] != null) const SizedBox(height: 8),
                if (userData['sex'] != null) Text('Gender: ${userData['sex']}'),
                if (userData['sex'] != null) const SizedBox(height: 8),
                if (userData['city'] != null) Text('City: ${userData['city']}'),
                if (userData['city'] != null) const SizedBox(height: 8),
                if (isStudent) ...[
                  if (userData['grade'] != null)
                    Text('Grade: ${userData['grade']}'),
                  if (userData['grade'] != null) const SizedBox(height: 8),
                  if (userData['subjects'] != null &&
                      (userData['subjects'] as List).isNotEmpty)
                    Text(
                      'Interested in: ${(userData['subjects'] as List).join(', ')}',
                    ),
                  if (userData['subjects'] != null &&
                      (userData['subjects'] as List).isNotEmpty)
                    const SizedBox(height: 8),
                  if (userData['learningGoals'] != null)
                    Text('Learning Goals: ${userData['learningGoals']}'),
                  if (userData['learningGoals'] != null)
                    const SizedBox(height: 8),
                ] else ...[
                  if (userData['qualification'] != null)
                    Text('Qualification: ${userData['qualification']}'),
                  if (userData['qualification'] != null)
                    const SizedBox(height: 8),
                  if (userData['subjects'] != null &&
                      (userData['subjects'] as List).isNotEmpty)
                    Text(
                      'Subjects: ${(userData['subjects'] as List).join(', ')}',
                    ),
                  if (userData['subjects'] != null &&
                      (userData['subjects'] as List).isNotEmpty)
                    const SizedBox(height: 8),
                  if (userData['gradeLevels'] != null &&
                      (userData['gradeLevels'] as List).isNotEmpty)
                    Text(
                      'Grade Levels: ${(userData['gradeLevels'] as List).join(', ')}',
                    ),
                  if (userData['gradeLevels'] != null &&
                      (userData['gradeLevels'] as List).isNotEmpty)
                    const SizedBox(height: 8),
                  if (userData['minPricePerHour'] != null)
                    Text('Price: Birr${userData['minPricePerHour']}/hr'),
                  if (userData['minPricePerHour'] != null)
                    const SizedBox(height: 8),
                  if (userData['hoursPerDay'] != null)
                    Text('Hours per day: ${userData['hoursPerDay']}'),
                  if (userData['hoursPerDay'] != null)
                    const SizedBox(height: 8),
                  if (userData['daysPerWeek'] != null)
                    Text('Days per week: ${userData['daysPerWeek']}'),
                  if (userData['daysPerWeek'] != null)
                    const SizedBox(height: 8),
                  if (userData['available'] != null)
                    Text(
                      'Available: ${userData['available'] == true ? 'Yes' : 'No'}',
                      style: TextStyle(
                        color: userData['available'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  if (userData['available'] != null) const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startChat(
                name,
                userId ?? '${isStudent ? 'student' : 'tutor'}_fake_id_$name',
                isStudent: isStudent,
              );
            },
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Creates a new stream for each search query
    Stream<QuerySnapshot> searchStream() async* {
      if (_searchQuery.isEmpty) {
        return;
      }
      try {
        final targetRole = _getSearchTargetRole();
        final collection = _getSearchTargetCollection();

        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('role', isEqualTo: targetRole)
            .where('name', isGreaterThanOrEqualTo: _searchQuery)
            .where('name', isLessThanOrEqualTo: '${_searchQuery}\uf8ff')
            .limit(20)
            .get();

        yield snapshot;
      } catch (e) {
        debugPrint('🔴 Stream Error: $e');
        yield* Stream<QuerySnapshot>.empty();
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: searchStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Searching...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          debugPrint('🔴 Search Error: $error');

          if (error.contains('index') ||
              error.contains('FAILED_PRECONDITION')) {
            debugPrint('🔧 INDEX REQUIRED: $error');
            return _buildIndexRequiredMessage();
          }

          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Search Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your connection or try again',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry Search'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('✅ No results found for "$_searchQuery"');
          return const Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No results found', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  'Try searching with a different name',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data!.docs;
        debugPrint(
          '✅ SERVER-SIDE SEARCH: Found ${results.length} results for "$_searchQuery"',
        );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fast Search Enabled',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Results from ${results.length} ${_userRole == 'tutor' ? 'students' : 'tutors'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...results.map((doc) => _buildSearchResultCard(doc)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildIndexRequiredMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.orange.shade600),
            const SizedBox(height: 24),
            const Text(
              'Search Optimization Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To enable fast search for 1000+ users, we need to create a search index.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text(
                      'Quick Fix:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Check your console for a Firebase index link\n'
                      '2. Click the link to create the index\n'
                      '3. Wait 2–5 minutes for it to build\n'
                      '4. Search will become instant!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.search),
              label: const Text('Use Basic Search For Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(DocumentSnapshot doc) {
    final userData = doc.data() as Map<String, dynamic>;
    final userId = doc.id;
    final name = userData['name'] ?? 'Unknown';
    final sex = userData['sex'] ?? '';
    final age = userData['age'];
    final city = userData['city'] ?? '';
    final subjects =
        (userData['subjects'] as List<dynamic>? ?? []).cast<String>();
    final gradeLevels =
        (userData['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
    final qualification = userData['qualification']?.toString();
    final available = userData['available'] == true;
    final profileImage = userData['profileImage'];
    final isVerified = userData['verified'] ?? false;

    final isStudent = _userRole == 'tutor';
    final displayInfo = isStudent
        ? userData['grade'] ?? 'Student'
        : 'Birr${userData['minPricePerHour'] ?? 0}/hr';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage:
              profileImage != null ? NetworkImage(profileImage) : null,
          child: profileImage == null
              ? Text(
                  name.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isVerified && !isStudent) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
            ],
            if (!isStudent) ...[
              const SizedBox(width: 8),
              RatingBadge(tutorId: userId),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                if (age is num) 'Age ${age.toInt()}',
                if (sex != '') sex,
                if (!isStudent && city.isNotEmpty) city,
              ].join(' • '),
            ),
            if (!isStudent && subjects.isNotEmpty)
              Text('Subjects: ${subjects.take(3).join(', ')}'),
            if (!isStudent && gradeLevels.isNotEmpty)
              Text('Grades: ${gradeLevels.take(3).join(', ')}'),
            if (!isStudent && qualification != null && qualification.isNotEmpty)
              Text('Qualification: $qualification'),
            if (!isStudent)
              Text(
                '${available ? 'Available' : 'Unavailable'} • $displayInfo',
                style: TextStyle(
                  color:
                      available ? Colors.green.shade700 : Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (isStudent) Text('$sex • $displayInfo'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.chat,
                color: Colors.green.shade600,
              ),
              onPressed: () {
                _startChat(name, userId, isStudent: isStudent);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.visibility,
                color: Colors.blue.shade700,
              ),
              onPressed: () {
                _viewProfile(
                  name,
                  isStudent: isStudent,
                  userId: userId,
                  userData: userData,
                );
              },
            ),
          ],
        ),
        onTap: () {
          if (!isStudent) {
            InteractionLogger.log(
              event: 'search_card_click',
              tutorId: userId,
              data: {'query': _searchQuery},
            );
          }
          _viewProfile(
            name,
            isStudent: isStudent,
            userId: userId,
            userData: userData,
          );
        },
      ),
    );
  }

  void _startChat(
    String personName,
    String personId, {
    bool isStudent = false,
  }) {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);

    final initialMessage = _userRole == 'tutor'
        ? "Hello! I'm interested in tutoring you."
        : "Hello! I'm interested in your tutoring services.";

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get()
        .then((doc) {
      String senderName;
      if (doc.exists && doc.data()?['name'] != null) {
        senderName = doc.data()!['name'];
      } else {
        senderName = _userName ?? (_userRole == 'tutor' ? 'Tutor' : 'Student');
      }

      if (!isStudent) {
        InteractionLogger.log(
          event: 'start_chat',
          tutorId: personId,
          data: {'source': 'home'},
        );
      }

      messageProvider
          .sendMessage(
        senderId: currentUser.uid,
        senderName: senderName,
        receiverId: personId,
        receiverName: personName,
        content: initialMessage,
      )
          .then((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              receiverId: personId,
              receiverName: personName,
            ),
          ),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $error')),
        );
      });
    }).catchError((error) {});
  }

  Widget _buildTopRatedList() {
    final targetRole = _userRole == 'tutor' ? 'student' : 'tutor';

    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: targetRole)
        .limit(3);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _userRole == 'tutor'
                  ? 'No students available.'
                  : 'No tutors available.',
            ),
          );
        }

        final users = snapshot.data!.docs;

        return Column(
          children: users.map((doc) {
            final user = doc.data() as Map<String, dynamic>;
            final name = user['name'] ?? 'Unknown';
            final sex = user['sex'] ?? '';
            final profileImage = user['profileImage'];
            final isVerified = user['verified'] ?? false;
            final isStudent = targetRole == 'student';

            final displayInfo = isStudent
                ? user['grade'] ?? 'Student'
                : 'Birr${user['minPricePerHour'] ?? 0}/hr';

            return _buildUserListItem(
              name,
              sex,
              displayInfo,
              doc.id,
              profileImage,
              isVerified,
              isStudent: isStudent,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(
    String name,
    String sex,
    String displayInfo,
    String userId,
    String? profileImage,
    bool isVerified, {
    bool isStudent = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage:
              profileImage != null ? NetworkImage(profileImage) : null,
          child: profileImage == null
              ? Text(
                  name.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isVerified && !isStudent) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
            ],
          ],
        ),
        subtitle: Text('$sex • $displayInfo'),
        trailing: IconButton(
          icon: Icon(
            Icons.chat,
            color: Colors.green.shade600,
            size: 20,
          ),
          onPressed: () {
            _startChat(name, userId, isStudent: isStudent);
          },
        ),
        onTap: () {
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get()
              .then((doc) {
            if (doc.exists) {
              _viewProfile(
                name,
                isStudent: isStudent,
                userId: userId,
                userData: doc.data() as Map<String, dynamic>,
              );
            }
          });
        },
      ),
    );
  }

  void _changeTheme(bool isDarkMode) {
    setState(() {
      // ThemeData is actually configured in build() via themeMode
      (context as Element).markNeedsBuild();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_userRole == 'tutor' ? 'Filter Students' : 'Filter Tutors'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Subject',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField(
                value: _selectedSubject,
                items: _subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedSubject = value!),
              ),
              const SizedBox(height: 16),
              const Text(
                'Grade Level',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField(
                value: _selectedGrade,
                items: _grades
                    .map(
                      (grade) => DropdownMenuItem(
                        value: grade,
                        child: Text(grade),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedGrade = value!),
              ),
              const SizedBox(height: 16),
              if (_userRole != 'tutor') ...[
                const Text(
                  'Max Price per Hour',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _priceRange,
                  min: 100,
                  max: 1000,
                  divisions: 9,
                  label: 'Birr$_priceRange',
                  onChanged: (value) => setState(() => _priceRange = value),
                ),
                Text(
                  'Birr$_priceRange',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _onlyVerified,
                      onChanged: (value) =>
                          setState(() => _onlyVerified = value!),
                    ),
                    const Text('Verified Tutors Only'),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please login to view messages'));
    }

    return StreamBuilder<List<Message>>(
      stream: Provider.of<MessageProvider>(context).getConversations(
        currentUser.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your conversations will appear here',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];

            final isCurrentUserSender =
                conversation.senderId == currentUser.uid;
            final otherPersonName = isCurrentUserSender
                ? conversation.receiverName
                : conversation.senderName;
            final otherPersonId = isCurrentUserSender
                ? conversation.receiverId
                : conversation.senderId;

            final isUnread = conversation.receiverId == currentUser.uid &&
                !conversation.isRead;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    otherPersonName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherPersonName,
                        style: TextStyle(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  conversation.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatTime(conversation.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: otherPersonId,
                        receiverName: otherPersonName,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'meeting_request':
        icon = Icons.person_add;
        iconColor = Colors.blue.shade700;
        break;
      case 'meeting_accepted':
        icon = Icons.check_circle;
        iconColor = Colors.green.shade700;
        break;
      case 'meeting_declined':
        icon = Icons.cancel;
        iconColor = Colors.red.shade700;
        break;
      case 'meeting_reminder':
        icon = Icons.access_time;
        iconColor = Colors.orange.shade700;
        break;
      case 'verification_required':
        icon = Icons.verified;
        iconColor = Colors.purple.shade700;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.w600,
            color: notification.isRead ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          notification.body,
          style: TextStyle(
            color: notification.isRead ? Colors.grey : Colors.black87,
          ),
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          Provider.of<NotificationProvider>(
            context,
            listen: false,
          ).markAsRead(notification.id);

          _handleNotificationTap(notification);
        },
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login to view notifications'),
      );
    }

    final currentUserId = currentUser.uid;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_none, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _userRole == 'tutor'
                        ? 'Stay updated with your teaching activities'
                        : 'Stay updated with your learning journey',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: Provider.of<NotificationProvider>(
                context,
                listen: true,
              ).getUserNotifications(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const ui.EmptyState(
                    icon: Icons.notifications_off,
                    title: 'No notifications yet',
                    message: 'Your notifications will appear here',
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    switch (notification.type) {
      case 'meeting_request':
        // TODO: navigate to meeting requests screen
        break;
      case 'meeting_accepted':
        // TODO: navigate to meeting details
        break;
      case 'meeting_reminder':
        // TODO: navigate to upcoming session
        break;
      default:
        break;
    }
  }

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _profileImage != null
                        ? NetworkImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blue.shade700,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userRole?.toUpperCase() ?? 'STUDENT',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat(
                        _userRole == 'tutor' ? 'Students' : 'Tutors',
                        '5',
                      ),
                      _buildProfileStat('Sessions', '12'),
                      _buildProfileStat('Rating', '4.8'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildProfileOption(
                  'Edit Profile',
                  Icons.edit_outlined,
                  onTap: () {
                    final role = _userRole ?? 'student';
                    switch (role) {
                      case 'tutor':
                        Navigator.pushNamed(context, '/tutor-info');
                        break;
                      case 'parent':
                        Navigator.pushNamed(context, '/parent-info');
                        break;
                      case 'student':
                      default:
                        Navigator.pushNamed(context, '/student-info');
                    }
                  },
                ),
                _buildProfileOption('Settings', Icons.settings_outlined),
                _buildProfileOption('Help & Support', Icons.help_outline),
                _buildProfileOption(
                  'Logout',
                  Icons.logout,
                  isLogout: true,
                  onTap: () async {
                    await authProvider.logout();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProfileOption(
    String title,
    IconData icon, {
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue.shade700),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Stream<int> _getUnreadMessageCount() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      return 0;
    });
  }

  Stream<int> _getUnreadNotificationCount() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      return 0;
    });
  }

  Stream<int> _getRelationshipAttentionCount() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    final uid = currentUser.uid;
    if (_userRole == 'tutor') {
      return FirebaseFirestore.instance
          .collection('meetingRequests')
          .where('toUserId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((s) => s.docs.length)
          .handleError((error) {
        return 0;
      });
    } else {
      return FirebaseFirestore.instance
          .collection('meetingRequests')
          .where('fromUserId', isEqualTo: uid)
          .where('status', isEqualTo: 'approved')
          .where('studentVerifiedMeeting', isEqualTo: false)
          .snapshots()
          .map((s) => s.docs.length)
          .handleError((error) {
        return 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(_getMainTitle()),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(), // index 0
              _buildMessagesTab(), // index 1
              _buildNotificationsTab(), // index 2
              const RelationshipsScreen(), // index 3
              _buildProfileTab(), // index 4
            ],
          ),
          bottomNavigationBar: StreamBuilder<int>(
            stream: _getUnreadMessageCount(),
            builder: (context, msgSnapshot) {
              final unreadMsgCount = msgSnapshot.data ?? 0;

              return StreamBuilder<int>(
                stream: _getUnreadNotificationCount(),
                builder: (context, notifSnapshot) {
                  final unreadNotifCount = notifSnapshot.data ?? 0;
                  final effectiveNotifCount =
                      _selectedIndex == 2 ? 0 : unreadNotifCount;

                  return StreamBuilder<int>(
                    stream: _getRelationshipAttentionCount(),
                    builder: (context, relSnapshot) {
                      final relCount = relSnapshot.data ?? 0;
                      final effectiveRelCount =
                          _selectedIndex == 3 ? 0 : relCount;

                      return Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: BottomNavigationBar(
                          currentIndex: _selectedIndex,
                          onTap: (index) {
                            setState(() => _selectedIndex = index);
                          },
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: Colors.white,
                          selectedItemColor: Colors.blue.shade700,
                          unselectedItemColor: Colors.grey.shade600,
                          selectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          items: [
                            const BottomNavigationBarItem(
                              icon: Icon(Icons.home_outlined),
                              activeIcon: Icon(Icons.home),
                              label: 'Home',
                            ),
                            BottomNavigationBarItem(
                              icon: Stack(
                                children: [
                                  const Icon(Icons.chat_bubble_outline),
                                  if (unreadMsgCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          unreadMsgCount > 99
                                              ? '99+'
                                              : unreadMsgCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              activeIcon: Stack(
                                children: [
                                  const Icon(Icons.chat),
                                  if (unreadMsgCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          unreadMsgCount > 99
                                              ? '99+'
                                              : unreadMsgCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              label: 'Messages',
                            ),
                            BottomNavigationBarItem(
                              icon: Stack(
                                children: [
                                  const Icon(Icons.notifications_outlined),
                                  if (effectiveNotifCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          effectiveNotifCount > 99
                                              ? '99+'
                                              : effectiveNotifCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              activeIcon: const Icon(Icons.notifications),
                              label: 'Notifications',
                            ),
                            BottomNavigationBarItem(
                              icon: Stack(
                                children: [
                                  const Icon(Icons.group_outlined),
                                  if (effectiveRelCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          effectiveRelCount > 99
                                              ? '99+'
                                              : effectiveRelCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              activeIcon: const Icon(Icons.group),
                              label: 'Relationships',
                            ),
                            const BottomNavigationBarItem(
                              icon: Icon(Icons.person_outlined),
                              activeIcon: Icon(Icons.person),
                              label: 'Profile',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
