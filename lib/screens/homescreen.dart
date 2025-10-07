import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:skillbridge/screens/categoryscreen.dart';
import 'package:skillbridge/screens/mentorprofilescreen.dart';
import 'package:skillbridge/screens/mentorsscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String? userName;
  bool isLoading = true;
  List<Map<String, dynamic>> popularPeople = [];

  final List<Map<String, dynamic>> trendingSkills = [
    {'name': 'Cooking', 'icon': Icons.kitchen},
    {'name': 'Gardening', 'icon': Icons.local_florist},
    {'name': 'Photography', 'icon': Icons.camera_alt},
    {'name': 'Bike Repair', 'icon': Icons.directions_bike},
    {'name': 'Painting', 'icon': Icons.brush},
    {'name': 'Language Tutoring', 'icon': Icons.language},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view users')),
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
      String? fetchedUserName = userDoc.exists ? userDoc['name']?.toString() : null;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      List<Map<String, dynamic>> fetchedUsers = querySnapshot.docs
          .where((doc) => doc.id != user.uid)
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> skills = List<String>.from(data['offeredSkills'] ?? []);
        return {
          'uid': doc.id,
          'name': data['name']?.toString() ?? 'Unknown',
          'bio': data['bio']?.toString() ?? 'No bio available',
          'email': data['email']?.toString() ?? 'No email provided',
          'mobile': data['mobile']?.toString() ?? 'No mobile number provided',
          'offeredSkills': skills,
          'wantedSkills': List<String>.from(data['wantedSkills'] ?? []),
          'imagePath': data['profileImagePath']?.toString(),
          'skill': skills.isNotEmpty ? skills[0] : 'No skills listed',
        };
      }).toList();

      print('Fetched ${fetchedUsers.length} users for Popular People');
      print('Current user name: $fetchedUserName');
      setState(() {
        userName = fetchedUserName;
        popularPeople = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _searchSkills(String query) async {
    if (query.isEmpty) return;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('offeredSkills', arrayContains: query)
          .get();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found ${querySnapshot.docs.length} users offering $query')),
      );
    } catch (e) {
      print('Error searching skills: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications page')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: Text(
          'Hello ${userName ?? ''} !',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _showNotifications,
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
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group, color: Colors.orange, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '"Connect, share, and grow your skills with our vibrant community!"',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Search for Skills',
                              labelStyle: TextStyle(color: Colors.orange),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            style: const TextStyle(color: Colors.black),
                            onFieldSubmitted: _searchSkills,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _searchSkills(_searchController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Trending Skills',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.to(() => const CategoryScreen());
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: trendingSkills.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Get.to(() => MentorsScreen(
                                        skill: trendingSkills[index]['name'],
                                      ));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.orange,
                                        child: Icon(
                                          trendingSkills[index]['icon'],
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        trendingSkills[index]['name'],
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Popular People',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.to(() => const CategoryScreen());
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                ),
                              )
                            : popularPeople.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No users found',
                                      style: TextStyle(fontSize: 16, color: Colors.black54),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: popularPeople.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        color: Colors.white,
                                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            radius: 25,
                                            backgroundColor: Colors.grey[300],
                                            backgroundImage: popularPeople[index]['imagePath'] != null &&
                                                    File(popularPeople[index]['imagePath']).existsSync()
                                                ? FileImage(File(popularPeople[index]['imagePath']))
                                                : null,
                                            child: popularPeople[index]['imagePath'] == null ||
                                                    !File(popularPeople[index]['imagePath']).existsSync()
                                                ? const Icon(Icons.person, color: Colors.grey)
                                                : null,
                                          ),
                                          title: Text(
                                            popularPeople[index]['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Skill: ${popularPeople[index]['skill']}',
                                                style: const TextStyle(color: Colors.black54),
                                              ),
                                              Text(
                                                popularPeople[index]['bio'],
                                                style: const TextStyle(color: Colors.black54),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            print('Navigating to MentorProfileScreen for UID: ${popularPeople[index]['uid']}');
                                            Get.to(() => MentorProfileScreen(
                                                  mentorId: popularPeople[index]['uid'],
                                                  name: popularPeople[index]['name'],
                                                  bio: popularPeople[index]['bio'],
                                                  email: popularPeople[index]['email'],
                                                  mobile: popularPeople[index]['mobile'],
                                                  offeredSkills: List<String>.from(popularPeople[index]['offeredSkills'] ?? []),
                                                  wantedSkills: List<String>.from(popularPeople[index]['wantedSkills'] ?? []),
                                                  profileImagePath: popularPeople[index]['imagePath'],
                                                ));
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}