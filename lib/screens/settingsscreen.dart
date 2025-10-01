import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:skillbridge/screens/signupscreen.dart';
import 'profilescreen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isDarkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _notificationsEnabled = data['settings']?['notificationsEnabled'] ?? true;
            _isDarkMode = data['settings']?['isDarkMode'] ?? false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'settings': {
              'notificationsEnabled': _notificationsEnabled,
              'isDarkMode': _isDarkMode,
            },
          },
          SetOptions(merge: true),
        );
        print('Settings saved for user: ${user.uid}');
      }
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const SignupScreen());
      print('User logged out');
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .get();
        for (var doc in chatSnapshot.docs) {
          await doc.reference.delete();
        }
        await user.delete();
        Get.offAll(() => const SignupScreen());
        print('Account deleted for user: ${user.uid}');
      } catch (e) {
        print('Error deleting account: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  color: const Color(0xFFF5F5F5),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  child: SwitchListTile(
                    title: const Text(
                      'Enable Notifications',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    value: _notificationsEnabled,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveUserSettings();
                    },
                  ),
                ),
                Card(
                  color: const Color(0xFFF5F5F5),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  child: SwitchListTile(
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    value: _isDarkMode,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                      _saveUserSettings();
                    },
                  ),
                ),
                Card(
                  color: const Color(0xFFF5F5F5),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  child: ListTile(
                    title: const Text(
                      'Edit Profile',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
                    onTap: () {
                      Get.to(() => const ProfileScreen());
                    },
                  ),
                ),
                Card(
                  color: const Color(0xFFF5F5F5),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  child: ListTile(
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.exit_to_app, color: Colors.orange),
                    onTap: _logout,
                  ),
                ),
                Card(
                  color: const Color(0xFFF5F5F5),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  child: ListTile(
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.delete, color: Colors.red),
                    onTap: _deleteAccount,
                  ),
                ),
              ],
            ),
    );
  }
}