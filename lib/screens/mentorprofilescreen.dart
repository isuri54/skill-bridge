import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'chatsscreen.dart';

class MentorProfileScreen extends StatelessWidget {
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

  Future<void> _navigateToChat(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to start a chat')),
        );
        return;
      }

      List<String> sortedParticipants = [user.uid, mentorId]..sort();
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
            recipientName: name,
            recipientId: mentorId,
          ));
    } catch (e) {
      print('Error navigating to chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
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
          name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: profileImagePath != null &&
                            File(profileImagePath!).existsSync()
                        ? FileImage(File(profileImagePath!))
                        : null,
                    child: profileImagePath == null ||
                            !File(profileImagePath!).existsSync()
                        ? const Icon(Icons.person, color: Colors.grey, size: 60)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bio.isNotEmpty ? bio : 'No bio available',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
              Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Schedule functionality coming soon')),
                        );
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reviews functionality coming soon')),
                        );
                      },
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
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
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
                        const Icon(Icons.email, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
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
                        const Icon(Icons.phone, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            mobile,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Offered Skills',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 500,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: offeredSkills.isNotEmpty
                          ? offeredSkills
                              .map((skill) => Chip(
                                    label: Text(
                                      skill,
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.orange),
                                  ))
                              .toList()
                          : [
                              const Text(
                                'No offered skills',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Wanted Skills',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 500,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: wantedSkills.isNotEmpty
                          ? wantedSkills
                              .map((skill) => Chip(
                                    label: Text(
                                      skill,
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.orange),
                                  ))
                              .toList()
                          : [
                              const Text(
                                'No wanted skills',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}