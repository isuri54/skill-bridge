import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillbridge/screens/homescreen.dart';

class SkillsSelectionScreen extends StatefulWidget {
  final String email;
  const SkillsSelectionScreen({super.key, required this.email});

  @override
  State<SkillsSelectionScreen> createState() => _SkillsSelectionScreenState();
}

class _SkillsSelectionScreenState extends State<SkillsSelectionScreen> {
  final _passwordController = TextEditingController();
  final Map<String, bool> _offeredSkills = {
    'Cooking': false,
    'Gardening': false,
    'Photography': false,
    'Language Tutoring': false,
    'Bike Repair': false,
  };
  final Map<String, bool> _wantedSkills = {
    'Cooking': false,
    'Gardening': false,
    'Photography': false,
    'Language Tutoring': false,
    'Bike Repair': false,
  };

  Future<void> _completeSignUp() async {
    try {
      DocumentSnapshot tempData = await FirebaseFirestore.instance.collection('temp_users').doc(widget.email).get();
      Map<String, dynamic> userData = tempData.data() as Map<String, dynamic>;

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: userData['password'],
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': userData['name'],
        'email': widget.email,
        'mobile': userData['mobile'],
        'bio': userData['bio'],
        'offeredSkills': _offeredSkills.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
        'wantedSkills': _wantedSkills.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
        'karma': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Delete temp data
      await FirebaseFirestore.instance.collection('temp_users').doc(widget.email).delete();

      // Navigate to a success page or home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF084C5C),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Skills You Offer:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._offeredSkills.keys.map((skill) => CheckboxListTile(
                    title: Text(skill, style: const TextStyle(color: Colors.white)),
                    value: _offeredSkills[skill],
                    onChanged: (value) {
                      setState(() {
                        _offeredSkills[skill] = value!;
                      });
                    },
                    checkColor: Colors.white,
                    activeColor: Colors.blueAccent,
                  )),
              const SizedBox(height: 20),
              const Text('Skills You Want:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._wantedSkills.keys.map((skill) => CheckboxListTile(
                    title: Text(skill, style: const TextStyle(color: Colors.white)),
                    value: _wantedSkills[skill],
                    onChanged: (value) {
                      setState(() {
                        _wantedSkills[skill] = value!;
                      });
                    },
                    checkColor: Colors.white,
                    activeColor: Colors.blueAccent,
                  )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _completeSignUp,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}