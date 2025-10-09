import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:skillbridge/screens/mentorprofilescreen.dart';

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
      print('Karma updated for user $userId: +$amount for $reason');
    } catch (e) {
      print('Error updating karma: $e');
    }
  }
}

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  _SchedulesScreenState createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  bool isLoadingSchedules = true;
  bool isLoadingRequests = true;
  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _fetchRequests();
  }

  Future<void> _fetchSchedules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view schedules')),
        );
        setState(() {
          schedules = [];
          isLoadingSchedules = false;
        });
        return;
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('scheduleRequests')
          .where('status', isEqualTo: 'accepted')
          .where('scheduledDateTime', isNotEqualTo: null)
          .orderBy('scheduledDateTime')
          .get();

      List<Map<String, dynamic>> fetchedSchedules = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['mentorId'] != user.uid && data['requesterId'] != user.uid) {
          continue;
        }
        String otherUserId = data['requesterId'] == user.uid ? data['mentorId'] : data['requesterId'];
        DocumentSnapshot otherUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();

        fetchedSchedules.add({
          'scheduleId': doc.id,
          'otherUserName': otherUserDoc.exists ? otherUserDoc['name'] : 'Unknown',
          'otherUserProfileImagePath': otherUserDoc.exists ? otherUserDoc['profileImagePath'] : null,
          'skill': data['skill'],
          'scheduledDateTime': data['scheduledDateTime'] != null
              ? (data['scheduledDateTime'] as Timestamp).toDate()
              : DateTime.now(),
          'isMentor': data['mentorId'] == user.uid,
          'completionConfirmedByMentor': data['completionConfirmedByMentor'] ?? false,
          'completionConfirmedByLearner': data['completionConfirmedByLearner'] ?? false,
        });
      }

      setState(() {
        schedules = fetchedSchedules.where((schedule) {
          return schedule['completionConfirmedByMentor'] == false ||
              schedule['completionConfirmedByLearner'] == false;
        }).toList();
        isLoadingSchedules = false;
      });
      print('Fetched ${schedules.length} schedules');
    } catch (e) {
      print('Error fetching schedules: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching schedules: $e')),
      );
      setState(() {
        schedules = [];
        isLoadingSchedules = false;
      });
    }
  }

  Future<void> _fetchRequests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        setState(() {
          requests = [];
          isLoadingRequests = false;
        });
        return;
      }

      print('Fetching requests for mentor UID: ${user.uid}');
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('scheduleRequests')
          .where('mentorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> fetchedRequests = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String requesterId = data['requesterId'];
        DocumentSnapshot requesterDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(requesterId)
            .get();

        fetchedRequests.add({
          'requestId': doc.id,
          'requesterName': requesterDoc.exists ? requesterDoc['name'] : 'Unknown',
          'requesterProfileImagePath': requesterDoc.exists ? requesterDoc['profileImagePath'] : null,
          'skill': data['skill'],
          'scheduledDateTime': data['scheduledDateTime'] != null
              ? (data['scheduledDateTime'] as Timestamp).toDate()
              : DateTime.now(),
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        });
      }

      print('Processed ${fetchedRequests.length} requests');
      setState(() {
        requests = fetchedRequests;
        isLoadingRequests = false;
      });
    } catch (e) {
      print('Error fetching requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching requests: $e')),
      );
      setState(() {
        requests = [];
        isLoadingRequests = false;
      });
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('scheduleRequests').doc(requestId).update({
        'status': status,
        'notified': false,
      });
      await _fetchRequests();
      await _fetchSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status')),
      );
    } catch (e) {
      print('Error updating request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating request: $e')),
      );
    }
  }

  Future<void> _deleteSchedule(String scheduleId, String mentorName) async {
    try {
      await FirebaseFirestore.instance.collection('scheduleRequests').doc(scheduleId).delete();
      await _fetchSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $mentorName\'s schedule')),
      );
    } catch (e) {
      print('Error deleting schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting schedule: $e')),
      );
    }
  }

  Future<void> _confirmCompletion(String scheduleId, bool isMentor) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('scheduleRequests').doc(scheduleId);
      final doc = await docRef.get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session not found')),
        );
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] != 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session not in accepted state')),
        );
        return;
      }

      final updateData = isMentor
          ? {'completionConfirmedByMentor': true}
          : {'completionConfirmedByLearner': true};
      await docRef.update(updateData);
      print('Confirmed completion for ${isMentor ? 'mentor' : 'learner'} on schedule $scheduleId');

      final updatedDoc = await docRef.get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      if (updatedData['completionConfirmedByMentor'] == true &&
          updatedData['completionConfirmedByLearner'] == true) {
        await docRef.update({'status': 'completed'});
        await KarmaSystem.updateKarma(data['mentorId'], 10, 'Completed mentoring session');
        await KarmaSystem.updateKarma(data['requesterId'], 2, 'Completed learning session');
        print('Session $scheduleId marked as completed, karma awarded');
      }

      await _fetchSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session completion confirmed')),
      );
    } catch (e) {
      print('Error confirming completion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming completion: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF084C5C),
          title: const Text('My Schedules', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Get.back();
            },
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            tabs: [
              const Tab(text: 'Upcoming Schedules'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (requests.length > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Text(
                          requests.length.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isLoadingSchedules
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                : schedules.isEmpty
                    ? const Center(
                        child: Text(
                          'No upcoming schedules',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          final isPast = schedule['scheduledDateTime']
                              .add(const Duration(hours: 1))
                              .isBefore(DateTime.now());
                          final mentorConfirmed = schedule['completionConfirmedByMentor'];
                          final learnerConfirmed = schedule['completionConfirmedByLearner'];
                          final user = FirebaseAuth.instance.currentUser;

                          return Card(
                            color: const Color(0xFFF5F5F5),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: schedule['otherUserProfileImagePath'] != null &&
                                        File(schedule['otherUserProfileImagePath']).existsSync()
                                    ? FileImage(File(schedule['otherUserProfileImagePath']))
                                    : null,
                                child: schedule['otherUserProfileImagePath'] == null ||
                                        !File(schedule['otherUserProfileImagePath']).existsSync()
                                    ? const Icon(Icons.person, color: Colors.grey)
                                    : null,
                              ),
                              title: Text(
                                schedule['otherUserName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Skill: ${schedule['skill']}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Time: ${DateFormat('MMM d, yyyy h:mm a').format(schedule['scheduledDateTime'])}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    schedule['isMentor'] ? 'Role: Mentor' : 'Role: Learner',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  if (isPast) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      mentorConfirmed ? 'Mentor confirmed' : 'Awaiting mentor confirmation',
                                      style: TextStyle(
                                        color: mentorConfirmed ? Colors.green : Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      learnerConfirmed ? 'Learner confirmed' : 'Awaiting learner confirmation',
                                      style: TextStyle(
                                        color: learnerConfirmed ? Colors.green : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPast &&
                                      ((schedule['isMentor'] && !mentorConfirmed) ||
                                          (!schedule['isMentor'] && !learnerConfirmed)))
                                    ElevatedButton(
                                      onPressed: () => _confirmCompletion(
                                        schedule['scheduleId'],
                                        schedule['isMentor'],
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Complete'),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.orange),
                                    onPressed: () {
                                      _deleteSchedule(
                                        schedule['scheduleId'],
                                        schedule['otherUserName'],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final otherUserId = schedule['isMentor']
                                    ? (await FirebaseFirestore.instance
                                        .collection('scheduleRequests')
                                        .doc(schedule['scheduleId'])
                                        .get())['requesterId']
                                    : (await FirebaseFirestore.instance
                                        .collection('scheduleRequests')
                                        .doc(schedule['scheduleId'])
                                        .get())['mentorId'];
                                final otherUserDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(otherUserId)
                                    .get();
                                Get.to(() => MentorProfileScreen(
                                      mentorId: otherUserId,
                                      name: otherUserDoc.exists ? otherUserDoc['name'] : 'Unknown',
                                      bio: otherUserDoc.exists ? otherUserDoc['bio'] ?? '' : '',
                                      email: otherUserDoc.exists ? otherUserDoc['email'] ?? '' : '',
                                      mobile: otherUserDoc.exists ? otherUserDoc['mobile'] ?? '' : '',
                                      offeredSkills:
                                          List<String>.from(otherUserDoc.exists ? otherUserDoc['offeredSkills'] ?? [] : []),
                                      wantedSkills:
                                          List<String>.from(otherUserDoc.exists ? otherUserDoc['wantedSkills'] ?? [] : []),
                                      profileImagePath: otherUserDoc.exists ? otherUserDoc['profileImagePath'] : null,
                                    ));
                              },
                            ),
                          );
                        },
                      ),
            isLoadingRequests
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                : requests.isEmpty
                    ? const Center(
                        child: Text(
                          'No pending requests',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: const Color(0xFFF5F5F5),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: requests[index]['requesterProfileImagePath'] != null &&
                                        File(requests[index]['requesterProfileImagePath']).existsSync()
                                    ? FileImage(File(requests[index]['requesterProfileImagePath']))
                                    : null,
                                child: requests[index]['requesterProfileImagePath'] == null ||
                                        !File(requests[index]['requesterProfileImagePath']).existsSync()
                                    ? const Icon(Icons.person, color: Colors.grey)
                                    : null,
                              ),
                              title: Text(
                                requests[index]['requesterName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Skill: ${requests[index]['skill']}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Time: ${DateFormat('MMM d, yyyy h:mm a').format(requests[index]['scheduledDateTime'])}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _updateRequestStatus(requests[index]['requestId'], 'accepted'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _updateRequestStatus(requests[index]['requestId'], 'declined'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}