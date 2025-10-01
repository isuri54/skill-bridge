import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String currentEmail;
  final List<String> currentOfferedSkills;
  final List<String> currentWantedSkills;
  final String? currentImagePath;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentBio,
    required this.currentEmail,
    required this.currentOfferedSkills,
    required this.currentWantedSkills,
    this.currentImagePath,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  String? _imageBase64;
  File? _selectedImage;
  final Map<String, bool> _offeredSkills = {
    'Cooking': false,
    'Gardening': false,
    'Photography': false,
    'Language Tutoring': false,
    'Bike Repair': false,
    'Painting': false,
    'Graphic Design': false,
    'Web Development': false,
    'Yoga Instruction': false,
    'Music Lessons': false,
    'Writing': false,
    'Knitting': false,
    'Carpentry': false,
    'Dance Instruction': false,
    'Coding Tutoring': false,
  };
  final Map<String, bool> _wantedSkills = {
    'Cooking': false,
    'Gardening': false,
    'Photography': false,
    'Language Tutoring': false,
    'Bike Repair': false,
    'Painting': false,
    'Graphic Design': false,
    'Web Development': false,
    'Yoga Instruction': false,
    'Music Lessons': false,
    'Writing': false,
    'Knitting': false,
    'Carpentry': false,
    'Dance Instruction': false,
    'Coding Tutoring': false,
  };

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _bioController.text = widget.currentBio;
    _emailController.text = widget.currentEmail;
    _imageBase64 = widget.currentImagePath;
    for (var skill in widget.currentOfferedSkills) {
      if (_offeredSkills.containsKey(skill)) {
        _offeredSkills[skill] = true;
      }
    }
    for (var skill in widget.currentWantedSkills) {
      if (_wantedSkills.containsKey(skill)) {
        _wantedSkills[skill] = true;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageBase64 = base64Image;
        });
        print('Picked image and converted to base64 (length: ${base64Image.length})');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'email': _emailController.text,
          'offeredSkills': _offeredSkills.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
          'wantedSkills': _wantedSkills.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
          if (_imageBase64 != null) 'profileImageBase64': _imageBase64,
        });
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : _imageBase64 != null
                            ? MemoryImage(base64Decode(_imageBase64!))
                            : const AssetImage('assets/images/userpng.png') as ImageProvider,
                    child: (_selectedImage == null && _imageBase64 == null)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: const Text(
                    'Change Profile Picture',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.black54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.black54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Colors.black54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Offered Skills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              ..._offeredSkills.keys.map((skill) => CheckboxListTile(
                    title: Text(skill, style: const TextStyle(color: Colors.black)),
                    value: _offeredSkills[skill],
                    onChanged: (value) {
                      setState(() {
                        _offeredSkills[skill] = value!;
                      });
                    },
                    checkColor: Colors.white,
                    activeColor: Colors.orange,
                  )),
              const SizedBox(height: 20),
              const Text(
                'Add Wanted Skills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              ..._wantedSkills.keys.map((skill) => CheckboxListTile(
                    title: Text(skill, style: const TextStyle(color: Colors.black)),
                    value: _wantedSkills[skill],
                    onChanged: (value) {
                      setState(() {
                        _wantedSkills[skill] = value!;
                      });
                    },
                    checkColor: Colors.white,
                    activeColor: Colors.orange,
                  )),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    fixedSize: const Size(200, 40),
                  ),
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}