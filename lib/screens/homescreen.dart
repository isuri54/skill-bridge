import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    {'name': 'Language Tutoring', 'icon': Icons.language},
    {'name': 'Bike Repair', 'icon': Icons.directions_bike},
    {'name': 'Painting', 'icon': Icons.brush},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch current user's name
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc['name'] as String?;
          });
        }

        // Fetch 6 random users for popular people
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .limit(6)
            .get();

        List<Map<String, dynamic>> fetchedPeople = userSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List<dynamic> skills = data['offeredSkills'] ?? [];
          String? imagePath = data['profileImagePath']?.toString();
          print('Fetched profileImagePath for ${data['name']}: $imagePath');
          return {
            'name': data['name']?.toString() ?? 'Unknown',
            'skill': skills.isNotEmpty ? skills[0].toString() : 'No skills listed',
            'bio': data['bio']?.toString() ?? 'No bio available',
            'imagePath': imagePath,
            'uid': doc.id,
          };
        }).toList();

        setState(() {
          popularPeople = fetchedPeople;
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('View all skills')),
                                );
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
                              return Padding(
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
                              );
                            },
                          ),
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
                              'Popular People',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('View all people')),
                                );
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
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