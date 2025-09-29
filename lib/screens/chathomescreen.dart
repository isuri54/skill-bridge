import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatsHomeScreen extends StatefulWidget {
  const ChatsHomeScreen({super.key});

  @override
  _ChatsHomeScreenState createState() => _ChatsHomeScreenState();
}

class _ChatsHomeScreenState extends State<ChatsHomeScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .orderBy('lastMessageTime', descending: true)
            .get();

        List<Map<String, dynamic>> fetchedChats = [];
        for (var doc in chatSnapshot.docs) {
          List<String> participants = List<String>.from(doc['participants']);
          String recipientId = participants.firstWhere((id) => id != user.uid);
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(recipientId)
              .get();
          
          fetchedChats.add({
            'chatId': doc.id,
            'recipientName': userDoc.exists ? userDoc['name'] : 'Unknown',
            'lastMessage': doc['lastMessage'] ?? 'No messages yet',
            'lastMessageTime': doc['lastMessageTime'] != null
                ? (doc['lastMessageTime'] as Timestamp).toDate()
                : DateTime.now(),
          });
        }

        setState(() {
          chats = fetchedChats;
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching chats: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showNewChatDialog() async {
    TextEditingController searchController = TextEditingController();
    List<Map<String, String>> users = [];
    bool isSearching = false;

    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(10)
          .get();
      users = userSnapshot.docs
          .map((doc) => {
                'uid': doc.id,
                'name': doc['name'] as String? ?? 'Unknown',
              })
          .toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Container(
          height: 300,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Users',
                  labelStyle: TextStyle(color: Colors.black54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    QuerySnapshot searchSnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('name', isGreaterThanOrEqualTo: value)
                        .where('name', isLessThanOrEqualTo: '$value\uf8ff')
                        .limit(10)
                        .get();
                    if (!mounted) return;
                    setState(() {
                      isSearching = true;
                      users = searchSnapshot.docs
                          .map((doc) => {
                                'uid': doc.id,
                                'name': doc['name'] as String? ?? 'Unknown',
                              })
                          .toList();
                    });
                  } else {
                    setState(() {
                      isSearching = false;
                    });
                    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .limit(10)
                        .get();
                    if (!mounted) return;
                    setState(() {
                      users = userSnapshot.docs
                          .map((doc) => {
                                'uid': doc.id,
                                'name': doc['name'] as String? ?? 'Unknown',
                              })
                          .toList();
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        users[index]['name']!,
                        style: const TextStyle(color: Colors.black),
                      ),
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          DocumentReference chatRef = await FirebaseFirestore.instance
                              .collection('chats')
                              .add({
                            'participants': [user.uid, users[index]['uid']],
                            'lastMessage': '',
                            'lastMessageTime': FieldValue.serverTimestamp(),
                          });
                          Get.back();
                          Get.to(());
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: const Text('Chats', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : chats.isEmpty
              ? const Center(
                  child: Text(
                    'No chats yet',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: const Color(0xFFF5F5F5),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          chats[index]['recipientName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              chats[index]['lastMessage'],
                              style: const TextStyle(color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, h:mm a').format(chats[index]['lastMessageTime']),
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () {
                          Get.to(());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}