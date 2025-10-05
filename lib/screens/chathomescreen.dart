import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:skillbridge/screens/chatsscreen.dart';

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
      if (user == null) {
        print('No user logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      print('Fetching chats for user UID: ${user.uid}');
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .get();

      print('Fetched ${chatSnapshot.docs.length} chat documents');
      Map<String, Map<String, dynamic>> uniqueChats = {};
      for (var doc in chatSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> participants = data['participants'] ?? [];
        if (participants.length != 2 || !participants.contains(user.uid)) {
          print('Skipping invalid chat document: ${doc.id}, participants: $participants');
          continue;
        }
        String recipientId = participants.firstWhere((id) => id != user.uid, orElse: () => '');
        if (recipientId.isEmpty) {
          print('No valid recipientId for chat: ${doc.id}');
          continue;
        }

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientId)
            .get();

        String recipientName = userDoc.exists && userDoc['name'] != null ? userDoc['name'] : 'Unknown';
        String? profileImagePath = userDoc.exists && userDoc['profileImagePath'] != null
            ? userDoc['profileImagePath']
            : null;

        Map<String, dynamic> viewedTimes = data['lastViewedTime'] ?? {};
        DateTime? lastViewedTime = viewedTimes[user.uid] != null
            ? (viewedTimes[user.uid] as Timestamp).toDate()
            : null;
        bool isUnread = data['lastMessageTime'] != null &&
            (lastViewedTime == null ||
                (data['lastMessageTime'] as Timestamp).toDate().isAfter(lastViewedTime));

        if (!uniqueChats.containsKey(recipientId) ||
            (data['lastMessageTime'] != null &&
                (uniqueChats[recipientId]!['lastMessageTime'] as DateTime)
                    .isBefore((data['lastMessageTime'] as Timestamp).toDate()))) {
          uniqueChats[recipientId] = {
            'chatId': doc.id,
            'recipientName': recipientName,
            'recipientId': recipientId,
            'lastMessage': data['lastMessage']?.toString() ?? 'No messages yet',
            'lastMessageTime': data['lastMessageTime'] != null
                ? (data['lastMessageTime'] as Timestamp).toDate()
                : DateTime.now(),
            'profileImagePath': profileImagePath,
            'isUnread': isUnread,
          };
        }
      }

      print('Processed ${uniqueChats.length} unique chats');
      setState(() {
        chats = uniqueChats.values.toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching chats: $e');
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
      print('Fetched ${users.length} users for new chat dialog');
    } catch (e) {
      print('Error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: MediaQuery.of(context).size.height * 0.2,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        content: Container(
          height: 300,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.orange),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
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
                      print('Search returned ${users.length} users');
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
                      print('Reset to ${users.length} random users');
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
                          String recipientId = users[index]['uid']!;
                          List<String> sortedParticipants = [user.uid, recipientId]..sort();
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
                            });
                            chatId = chatRef.id;
                            print('Created new chat: $chatId for participants: $sortedParticipants');
                          }

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          Get.to(() => ChatScreen(
                                chatId: chatId!,
                                recipientName: users[index]['name']!,
                                recipientId: recipientId,
                              ));
                          await _fetchChats();
                          print('Refreshed chats after navigation');
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10.0),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: chats[index]['profileImagePath'] != null &&
                                File(chats[index]['profileImagePath']).existsSync()
                            ? FileImage(File(chats[index]['profileImagePath']))
                            : null,
                        child: chats[index]['profileImagePath'] == null ||
                                !File(chats[index]['profileImagePath']).existsSync()
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chats[index]['recipientName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, h:mm a').format(chats[index]['lastMessageTime']),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        chats[index]['lastMessage'],
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: chats[index]['isUnread'] ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chats[index]['chatId'])
                              .update({
                            'lastViewedTime.${user.uid}': FieldValue.serverTimestamp(),
                          });
                        }
                        Get.to(() => ChatScreen(
                              chatId: chats[index]['chatId'],
                              recipientName: chats[index]['recipientName'],
                              recipientId: chats[index]['recipientId'],
                            ));
                        await _fetchChats();
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