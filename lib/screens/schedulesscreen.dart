import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  _SchedulesScreenState createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> schedules = [];

  final List<Map<String, dynamic>> dummySchedules = [
    {
      'mentorName': 'Alice Smith',
      'skill': 'Cooking',
      'time': '2025-09-26 10:00 AM',
    },
    {
      'mentorName': 'Bob Johnson',
      'skill': 'Gardening',
      'time': '2025-09-26 02:00 PM',
    },
    {
      'mentorName': 'Clara Lee',
      'skill': 'Photography',
      'time': '2025-09-27 11:00 AM',
    },
    {
      'mentorName': 'Fred Jansen',
      'skill': 'Bike Repair',
      'time': '2025-09-28 11:00 AM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('schedules')
            .where('userId', isEqualTo: user.uid)
            .get();

        setState(() {
          schedules = querySnapshot.docs.isNotEmpty
              ? querySnapshot.docs
                  .map((doc) => {
                        'mentorName': doc['mentorName'] as String,
                        'skill': doc['skill'] as String,
                        'time': doc['time'] as String,
                      })
                  .toList()
              : dummySchedules;
          isLoading = false;
        });
      } else {
        setState(() {
          schedules = dummySchedules;
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching schedules: $e')),
      );
      setState(() {
        schedules = dummySchedules;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: const Text('My Schedules', style: TextStyle(color: Colors.white),),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: const Color(0xFFF5F5F5),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text(
                              schedules[index]['mentorName'],
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
                                  'Time: ${schedules[index]['time']}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.orange),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Delete ${schedules[index]['mentorName']}\'s schedule')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}