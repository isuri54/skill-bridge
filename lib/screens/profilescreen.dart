import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:skillbridge/screens/editprofile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String? userName;
  String? bio;
  List<String> offeredSkills = [];
  List<String> wantedSkills = [];
  String? profileImagePath;

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
            bio = userDoc['bio'] as String?;
            offeredSkills = List<String>.from(userDoc['offeredSkills'] ?? []);
            wantedSkills = List<String>.from(userDoc['wantedSkills'] ?? []);
            profileImagePath = userDoc['profileImagePath'] as String?;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Get.to(() => EditProfileScreen(
                    currentName: userName ?? '',
                    currentBio: bio ?? '',
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit profile to change picture')),
                          );
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: profileImagePath != null && File(profileImagePath!).existsSync()
                              ? FileImage(File(profileImagePath!))
                              : const AssetImage('assets/images/userpng.png') as ImageProvider,
                          backgroundColor: Colors.grey[300],
                        ),
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
                          const Text(
                            'Name',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userName ?? 'Unknown',
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                          const Text(
                            'Bio',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio ?? 'No bio provided',
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                          const Text(
                            'Offered Skills',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          offeredSkills.isNotEmpty
                              ? Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: offeredSkills
                                      .map((skill) => Chip(
                                            label: Text(skill),
                                            backgroundColor: Colors.orange.withOpacity(0.2),
                                            labelStyle: const TextStyle(color: Colors.black),
                                          ))
                                      .toList(),
                                )
                              : const Text(
                                  'No skills offered',
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
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
                                            backgroundColor: Colors.orange.withOpacity(0.2),
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
                  ],
                ),
              ),
            ),
    );
  }
}