import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:skillbridge/screens/mentorprofilescreen.dart';

class MentorsScreen extends StatefulWidget {
  final String skill;

  const MentorsScreen({super.key, required this.skill});

  @override
  _MentorsScreenState createState() => _MentorsScreenState();
}

class _MentorsScreenState extends State<MentorsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> mentors = [];

  @override
  void initState() {
    super.initState();
    _fetchMentors();
  }

  Future<void> _fetchMentors() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('offeredSkills', arrayContains: widget.skill)
          .get();

      List<Map<String, dynamic>> fetchedMentors = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'name': data['name']?.toString() ?? 'Unknown',
          'bio': data['bio']?.toString() ?? 'No bio available',
          'email': data['email']?.toString() ?? 'No email provided',
          'mobile': data['mobile']?.toString() ?? 'No mobile number provided',
          'offeredSkills': List<String>.from(data['offeredSkills'] ?? []),
          'wantedSkills': List<String>.from(data['wantedSkills'] ?? []),
          'profileImagePath': data['profileImagePath']?.toString(),
        };
      }).toList();

      print('Fetched ${fetchedMentors.length} mentors for skill: ${widget.skill}');
      setState(() {
        mentors = fetchedMentors;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching mentors: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching mentors: $e')),
      );
      setState(() {
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
        title: Text(
          '${widget.skill} Mentors',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : mentors.isEmpty
              ? Center(
                  child: Text(
                    'No mentors found for ${widget.skill}',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: mentors.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: const Color(0xFFF5F5F5),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: mentors[index]['profileImagePath'] != null &&
                                  File(mentors[index]['profileImagePath']).existsSync()
                              ? FileImage(File(mentors[index]['profileImagePath']))
                              : null,
                          child: mentors[index]['profileImagePath'] == null ||
                                  !File(mentors[index]['profileImagePath']).existsSync()
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        title: Text(
                          mentors[index]['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          mentors[index]['bio'],
                          style: const TextStyle(color: Colors.black54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Get.to(() => MentorProfileScreen(
                                mentorId: mentors[index]['uid'],
                                name: mentors[index]['name'],
                                bio: mentors[index]['bio'],
                                email: mentors[index]['email'] ?? 'No email provided',
                                mobile: mentors[index]['mobile'],
                                offeredSkills: List<String>.from(mentors[index]['offeredSkills'] ?? []),
                                wantedSkills: List<String>.from(mentors[index]['wantedSkills'] ?? []),
                                profileImagePath: mentors[index]['profileImagePath'],
                              ));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}