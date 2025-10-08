import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:skillbridge/screens/editprofile.dart';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String? userName;
  String? bio;
  String? email;
  String? mobile;
  List<String> offeredSkills = [];
  List<String> wantedSkills = [];
  String? profileImagePath;
  int sessionsMentored = 0;
  int sessionsLearned = 0;
  double totalHoursMentored = 0.0;
  DateTime? profileCreatedAt;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view profile')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      QuerySnapshot mentorSessions = await FirebaseFirestore.instance
          .collection('scheduleRequests')
          .where('mentorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'accepted')
          .where('scheduledDateTime', isLessThan: Timestamp.fromDate(DateTime.now()))
          .get();

      QuerySnapshot learnerSessions = await FirebaseFirestore.instance
          .collection('scheduleRequests')
          .where('requesterId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'accepted')
          .where('scheduledDateTime', isLessThan: Timestamp.fromDate(DateTime.now()))
          .get();

      int mentorCount = mentorSessions.docs.length;
      int learnerCount = learnerSessions.docs.length;
      double hoursMentored = mentorCount * 1.0;

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] as String?;
          bio = userDoc['bio'] as String?;
          email = userDoc['email'] as String?;
          mobile = userDoc['mobile'] as String?;
          offeredSkills = List<String>.from(userDoc['offeredSkills'] ?? []);
          wantedSkills = List<String>.from(userDoc['wantedSkills'] ?? []);
          profileImagePath = userDoc['profileImagePath'] as String?;
          profileCreatedAt = userDoc['createdAt'] != null
              ? (userDoc['createdAt'] as Timestamp).toDate()
              : null;
          sessionsMentored = mentorCount;
          sessionsLearned = learnerCount;
          totalHoursMentored = hoursMentored;
          isLoading = false;
        });
        print('Fetched user data: name=$userName, sessionsMentored=$sessionsMentored, sessionsLearned=$sessionsLearned');
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Get.to(() => EditProfileScreen(
                    currentName: userName ?? '',
                    currentBio: bio ?? '',
                    currentEmail: email ?? '',
                    currentOfferedSkills: offeredSkills,
                    currentWantedSkills: wantedSkills,
                    currentImagePath: profileImagePath,
                  ));
            },
          ),
        ],
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
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit profile to change picture')),
                            );
                          },
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: profileImagePath != null && File(profileImagePath!).existsSync()
                                ? FileImage(File(profileImagePath!))
                                : const AssetImage('assets/images/userpng.png') as ImageProvider,
                            backgroundColor: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bio ?? 'No bio provided',
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: const Color(0xFFF5F5F5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: user != null
                          ? KarmaDisplay(
                              userId: user.uid,
                              showHistory: true,
                            )
                          : const Text('No user logged in'),
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
                              if (offeredSkills.length >= 3)
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
                                email ?? 'No email provided',
                                style: const TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ],
                          ),
                          if (mobile != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  mobile!,
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
                          const SizedBox(height: 8, width: 330),
                          offeredSkills.isNotEmpty
                              ? Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: offeredSkills
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
                          wantedSkills.isNotEmpty
                              ? Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: wantedSkills
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

// Helper widget for statistics
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