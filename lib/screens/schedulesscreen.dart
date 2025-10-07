import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';

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
          .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .where('scheduledDateTime', isLessThan: Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))))
          .orderBy('scheduledDateTime')
          .get();

      List<Map<String, dynamic>> fetchedSchedules = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
        });
      }

      setState(() {
        schedules = fetchedSchedules;
        isLoadingSchedules = false;
      });
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

      print('Query returned ${querySnapshot.docs.length} documents');
      for (var doc in querySnapshot.docs) {
        print('Document ID: ${doc.id}, Data: ${doc.data()}');
      }

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
            // Upcoming Schedules Tab
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
                          return Card(
                            color: const Color(0xFFF5F5F5),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: schedules[index]['otherUserProfileImagePath'] != null &&
                                        File(schedules[index]['otherUserProfileImagePath']).existsSync()
                                    ? FileImage(File(schedules[index]['otherUserProfileImagePath']))
                                    : null,
                                child: schedules[index]['otherUserProfileImagePath'] == null ||
                                        !File(schedules[index]['otherUserProfileImagePath']).existsSync()
                                    ? const Icon(Icons.person, color: Colors.grey)
                                    : null,
                              ),
                              title: Text(
                                schedules[index]['otherUserName'],
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
                                    'Skill: ${schedules[index]['skill']}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Time: ${DateFormat('MMM d, yyyy h:mm a').format(schedules[index]['scheduledDateTime'])}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    schedules[index]['isMentor'] ? 'Role: Mentor' : 'Role: Learner',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.orange),
                                onPressed: () {
                                  _deleteSchedule(
                                    schedules[index]['scheduleId'],
                                    schedules[index]['otherUserName'],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
            // Requests Tab
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