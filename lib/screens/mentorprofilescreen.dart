import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:skillbridge/screens/makeschedulescreen.dart';
import 'package:skillbridge/screens/chatsscreen.dart';
import 'package:intl/intl.dart';

class KarmaSystem {
  static Future<int> getUserKarma(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.exists ? userDoc['karma'] as int? ?? 0 : 0;
    } catch (e) {
      print('Error fetching karma: $e');
      return 0;
    }
  }

  static Stream<QuerySnapshot> getKarmaHistory(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('karmaHistory')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> updateKarma(String userId, int amount, String reason) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'karma': FieldValue.increment(amount),
      });
      await userRef.collection('karmaHistory').add({
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating karma: $e');
    }
  }
}

class KarmaDisplay extends StatelessWidget {
  final String userId;
  final bool showHistory;

  const KarmaDisplay({
    super.key,
    required this.userId,
    this.showHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<int>(
          future: KarmaSystem.getUserKarma(userId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Row(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Karma: ${snapshot.data}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            }
            return const CircularProgressIndicator();
          },
        ),
        if (showHistory)
          StreamBuilder<QuerySnapshot>(
            stream: KarmaSystem.getKarmaHistory(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error loading karma history');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No karma history');
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  int amount = data['amount'] as int;
                  String reason = data['reason'] as String;
                  DateTime timestamp = (data['timestamp'] as Timestamp).toDate();

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        amount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: amount > 0 ? Colors.green : Colors.red,
                      ),
                      title: Text('${amount > 0 ? '+' : ''}$amount Karma'),
                      subtitle: Text('$reason • ${DateFormat('MMM d, yyyy h:mm a').format(timestamp)}'),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class MentorProfileScreen extends StatefulWidget {
  final String mentorId;
  final String name;
  final String bio;
  final String email;
  final String mobile;
  final List<String> offeredSkills;
  final List<String> wantedSkills;
  final String? profileImagePath;

  const MentorProfileScreen({
    super.key,
    required this.mentorId,
    required this.name,
    required this.bio,
    required this.email,
    required this.mobile,
    required this.offeredSkills,
    required this.wantedSkills,
    this.profileImagePath,
  });

  @override
  _MentorProfileScreenState createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  bool isLoading = true;
  int sessionsMentored = 0;
  int sessionsLearned = 0;
  double totalHoursMentored = 0.0;
  DateTime? profileCreatedAt;
  bool hasCompletedSession = false;

  @override
  void initState() {
    super.initState();
    _fetchMentorData();
    _checkCompletedSession();
  }

  Future<void> _fetchMentorData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mentorId)
          .get();

      QuerySnapshot mentorSessions = await FirebaseFirestore.instance
          .collection('scheduleRequests')
          .where('mentorId', isEqualTo: widget.mentorId)
          .where('status', isEqualTo: 'completed')
          .get();

      QuerySnapshot learnerSessions = await FirebaseFirestore.instance
          .collection('scheduleRequests')
          .where('requesterId', isEqualTo: widget.mentorId)
          .where('status', isEqualTo: 'completed')
          .get();

      int mentorCount = mentorSessions.docs.length;
      int learnerCount = learnerSessions.docs.length;
      double hoursMentored = mentorCount * 1.0;

      if (userDoc.exists) {
        setState(() {
          profileCreatedAt = userDoc['createdAt'] != null
              ? (userDoc['createdAt'] as Timestamp).toDate()
              : null;
          sessionsMentored = mentorCount;
          sessionsLearned = learnerCount;
          totalHoursMentored = hoursMentored;
          isLoading = false;
        });
        print('Fetched mentor data: name=${widget.name}, sessionsMentored=$sessionsMentored, sessionsLearned=$sessionsLearned');
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching mentor data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching mentor data: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkCompletedSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          hasCompletedSession = false;
        });
        return;
      }
      QuerySnapshot completedSessions = await FirebaseFirestore.instance
          .collection('scheduleRequests')
          .where('mentorId', isEqualTo: widget.mentorId)
          .where('requesterId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();
      setState(() {
        hasCompletedSession = completedSessions.docs.isNotEmpty;
      });
      print('Completed session check: hasCompletedSession=$hasCompletedSession');
    } catch (e) {
      print('Error checking completed session: $e');
      setState(() {
        hasCompletedSession = false;
      });
    }
  }

  Future<void> _navigateToChat(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to start a chat')),
        );
        return;
      }

      List<String> sortedParticipants = [user.uid, widget.mentorId]..sort();
      QuerySnapshot existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', isEqualTo: sortedParticipants)
          .limit(1)
          .get();

      String? chatId;
      if (existingChat.docs.isNotEmpty) {
        chatId = existingChat.docs.first.id;
        print('Found existing chat: $chatId for participants: $sortedParticipants');
      } else {
        DocumentReference chatRef = await FirebaseFirestore.instance
            .collection('chats')
            .add({
          'participants': sortedParticipants,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastViewedTime': {
            user.uid: FieldValue.serverTimestamp(),
          },
        });
        chatId = chatRef.id;
        print('Created new chat: $chatId for participants: $sortedParticipants');
      }

      Get.to(() => ChatScreen(
            chatId: chatId!,
            recipientName: widget.name,
            recipientId: widget.mentorId,
          ));
    } catch (e) {
      print('Error navigating to chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  Future<void> _showAddReviewDialog() async {
    int rating = 1;
    TextEditingController commentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rating:'),
            DropdownButton<int>(
              value: rating,
              items: List.generate(5, (index) => index + 1)
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value Star${value > 1 ? 's' : ''}'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  rating = value;
                  (context as Element).markNeedsBuild();
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();
                String reviewerName = userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown';
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.mentorId)
                    .collection('reviews')
                    .add({
                  'reviewerId': user.uid,
                  'reviewerName': reviewerName,
                  'rating': rating,
                  'comment': commentController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                });
                print('Review submitted: rating=$rating, comment=${commentController.text}');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review submitted')),
                );
              } catch (e) {
                print('Error submitting review: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error submitting review: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showReviewsSnackBar() async {
    try {
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mentorId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      List<Widget> reviewWidgets = [];
      if (reviewsSnapshot.docs.isEmpty) {
        reviewWidgets.add(const Text('No reviews yet', style: TextStyle(color: Colors.black54)));
      } else {
        for (var doc in reviewsSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          int rating = data['rating'] ?? 0;
          String comment = data['comment'] ?? '';
          String reviewerName = data['reviewerName'] ?? 'Unknown';
          DateTime timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

          reviewWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      rating,
                      (index) => const Icon(Icons.star, color: Colors.orange, size: 16),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$reviewerName: $comment', style: const TextStyle(color: Colors.black)),
                  Text(
                    DateFormat('MMM d, yyyy').format(timestamp),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: reviewWidgets,
            ),
          ),
          action: SnackBarAction(
            label: 'Add Review',
            textColor: hasCompletedSession ? Colors.orange : Colors.grey,
            disabledTextColor: Colors.grey,
            onPressed: hasCompletedSession
                ? () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _showAddReviewDialog();
                  }
                : () {},
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('Error fetching reviews: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reviews: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: Text(
          widget.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: widget.profileImagePath != null &&
                                  File(widget.profileImagePath!).existsSync()
                              ? FileImage(File(widget.profileImagePath!))
                              : null,
                          child: widget.profileImagePath == null ||
                                  !File(widget.profileImagePath!).existsSync()
                              ? const Icon(Icons.person, color: Colors.grey, size: 60)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.bio.isNotEmpty ? widget.bio : 'No bio provided',
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _navigateToChat(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Chat'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Get.to(() => MakeScheduleScreen(
                                  mentorId: widget.mentorId,
                                  mentorName: widget.name,
                                  profileImagePath: widget.profileImagePath,
                                  offeredSkills: widget.offeredSkills,
                                ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Make Schedule'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _showReviewsSnackBar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Reviews'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  Card(
                    color: const Color(0xFFF5F5F5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: KarmaDisplay(
                        userId: widget.mentorId,
                        showHistory: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  Card(
                    color: const Color(0xFFF5F5F5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistics',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatItem(
                                label: 'Sessions Mentored',
                                value: sessionsMentored.toString(),
                                icon: Icons.school,
                              ),
                              _StatItem(
                                label: 'Sessions Learned',
                                value: sessionsLearned.toString(),
                                icon: Icons.book,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatItem(
                                label: 'Hours Mentored',
                                value: totalHoursMentored.toStringAsFixed(1),
                                icon: Icons.timer,
                              ),
                              _StatItem(
                                label: 'Profile Since',
                                value: profileCreatedAt != null
                                    ? DateFormat('MMM yyyy').format(profileCreatedAt!)
                                    : 'N/A',
                                icon: Icons.calendar_today,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  Card(
                    color: const Color(0xFFF5F5F5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Achievements',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 12, width: 330,),
                          Wrap(
                            spacing: 12.0,
                            runSpacing: 12.0,
                            children: [
                              if (sessionsMentored >= 1)
                                _AchievementBadge(
                                  title: 'First Session',
                                  icon: Icons.star,
                                  color: Colors.orange,
                                ),
                              if (sessionsMentored >= 5)
                                _AchievementBadge(
                                  title: 'Mentor Pro',
                                  icon: Icons.star_border,
                                  color: Colors.orange,
                                ),
                              if (widget.offeredSkills.length >= 3)
                                _AchievementBadge(
                                  title: 'Skill Sharer',
                                  icon: Icons.share,
                                  color: Colors.orange,
                                ),
                              if (sessionsLearned >= 1)
                                _AchievementBadge(
                                  title: 'Eager Learner',
                                  icon: Icons.bookmark,
                                  color: Colors.orange,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  Card(
                    color: const Color(0xFFF5F5F5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.email, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.email,
                                style: const TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ],
                          ),
                          if (widget.mobile.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  widget.mobile,
                                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  Card(
                    color: const Color(0xFFF5F5F5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Offered Skills',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8, width: 330,),
                          widget.offeredSkills.isNotEmpty
                              ? Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: widget.offeredSkills
                                      .map((skill) => Chip(
                                            label: Text(skill),
                                            backgroundColor: Colors.orange,
                                            labelStyle: const TextStyle(color: Colors.black),
                                          ))
                                      .toList(),
                                )
                              : const Text(
                                  'No skills offered',
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                          const SizedBox(height: 20),
                          const Text(
                            'Wanted Skills',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          widget.wantedSkills.isNotEmpty
                              ? Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: widget.wantedSkills
                                      .map((skill) => Chip(
                                            label: Text(skill),
                                            backgroundColor: Colors.orange,
                                            labelStyle: const TextStyle(color: Colors.black),
                                          ))
                                      .toList(),
                                )
                              : const Text(
                                  'No skills wanted',
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widget for achievement badges
class _AchievementBadge extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _AchievementBadge({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}