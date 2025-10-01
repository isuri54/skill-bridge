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

  final List<Map<String, dynamic>> trendingSkills = [
    {'name': 'Cooking', 'icon': Icons.kitchen},
    {'name': 'Gardening', 'icon': Icons.local_florist},
    {'name': 'Photography', 'icon': Icons.camera_alt},
    {'name': 'Language Tutoring', 'icon': Icons.language},
    {'name': 'Bike Repair', 'icon': Icons.directions_bike},
    {'name': 'Painting', 'icon': Icons.brush},
  ];

  final List<Map<String, dynamic>> popularPeople = [
    {
      'name': 'Alice Smith',
      'skill': 'Cooking',
      'bio': 'Passionate chef sharing culinary skills.',
      'rating': 4.8,
      'image': 'https://via.placeholder.com/50',
    },
    {
      'name': 'Bob Johnson',
      'skill': 'Gardening',
      'bio': 'Expert in organic gardening.',
      'rating': 4.5,
      'image': 'https://via.placeholder.com/50',
    },
    {
      'name': 'Clara Lee',
      'skill': 'Photography',
      'bio': 'Capturing moments with creativity.',
      'rating': 4.7,
      'image': 'https://via.placeholder.com/50',
    },
    {
      'name': 'David Kim',
      'skill': 'Language Tutoring',
      'bio': 'Fluent in 3 languages, eager to teach.',
      'rating': 4.9,
      'image': 'https://via.placeholder.com/50',
    },
    {
      'name': 'Emma Brown',
      'skill': 'Bike Repair',
      'bio': 'Fixing bikes with precision.',
      'rating': 4.6,
      'image': 'https://via.placeholder.com/50',
    },
    {
      'name': 'Frank Wilson',
      'skill': 'Painting',
      'bio': 'Creating art with vibrant colors.',
      'rating': 4.4,
      'image': 'https://via.placeholder.com/50',
    },
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
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc['name'] as String?;
            isLoading = false;
          });
        }
      }
    } catch (e) {
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
        backgroundColor: Color(0xFF084C5C),
        title: Text('Hello ${userName ?? ''} !', style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _showNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                                  backgroundImage: NetworkImage(popularPeople[index]['image']),
                                  radius: 25,
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
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.orange, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          popularPeople[index]['rating'].toString(),
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                      ],
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