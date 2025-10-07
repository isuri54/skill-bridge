import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class MakeScheduleScreen extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  final String? profileImagePath;
  final List<String> offeredSkills;

  const MakeScheduleScreen({
    super.key,
    required this.mentorId,
    required this.mentorName,
    this.profileImagePath,
    required this.offeredSkills,
  });

  @override
  _MakeScheduleScreenState createState() => _MakeScheduleScreenState();
}

class _MakeScheduleScreenState extends State<MakeScheduleScreen> {
  String? selectedSkill;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.offeredSkills.isNotEmpty) {
      selectedSkill = widget.offeredSkills[0];
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _requestSchedule() async {
    if (selectedSkill == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill, date, and time')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        return;
      }

      final scheduledDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      await FirebaseFirestore.instance.collection('scheduleRequests').add({
        'requesterId': user.uid,
        'mentorId': widget.mentorId,
        'skill': selectedSkill,
        'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule request sent successfully')),
      );
    } catch (e) {
      print('Error requesting schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting schedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: const Text('Make Schedule', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: widget.profileImagePath != null &&
                            File(widget.profileImagePath!).existsSync()
                        ? FileImage(File(widget.profileImagePath!))
                        : null,
                    child: widget.profileImagePath == null ||
                            !File(widget.profileImagePath!).existsSync()
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.mentorName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Offered skill selection
              const Text(
                'Select Skill',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.offeredSkills.isEmpty)
                const Text(
                  'No skills offered',
                  style: TextStyle(color: Colors.black54),
                )
              else if (widget.offeredSkills.length == 1)
                Text(
                  widget.offeredSkills[0],
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                )
              else
                Column(
                  children: widget.offeredSkills.map((skill) => RadioListTile<String>(
                        title: Text(skill, style: const TextStyle(color: Colors.black)),
                        value: skill,
                        groupValue: selectedSkill,
                        activeColor: Colors.orange,
                        onChanged: (value) {
                          setState(() {
                            selectedSkill = value;
                          });
                        },
                      )).toList(),
                ),
              const SizedBox(height: 20),
              // Date selection
              const Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectDate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  selectedDate == null
                      ? 'Choose Date'
                      : DateFormat('MMM d, yyyy').format(selectedDate!),
                ),
              ),
              const SizedBox(height: 20),
              // Time selection
              const Text(
                'Select Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  selectedTime == null
                      ? 'Choose Time'
                      : DateFormat('h:mm a').format(DateTime(2020, 1, 1, selectedTime!.hour, selectedTime!.minute)),
                ),
              ),
              const SizedBox(height: 20),
              // Request Schedule button
              Center(
                child: ElevatedButton(
                  onPressed: _requestSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    fixedSize: const Size(200, 40),
                  ),
                  child: const Text('Request Schedule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}