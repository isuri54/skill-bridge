import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mentorsscreen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Cooking', 'icon': Icons.kitchen},
    {'name': 'Gardening', 'icon': Icons.local_florist},
    {'name': 'Photography', 'icon': Icons.camera_alt},
    {'name': 'Language Tutoring', 'icon': Icons.language},
    {'name': 'Bike Repair', 'icon': Icons.directions_bike},
    {'name': 'Painting', 'icon': Icons.brush},
    {'name': 'Graphic Design', 'icon': Icons.design_services},
    {'name': 'Web Development', 'icon': Icons.code},
    {'name': 'Yoga Instruction', 'icon': Icons.self_improvement},
    {'name': 'Music Lessons', 'icon': Icons.music_note},
    {'name': 'Writing', 'icon': Icons.edit},
    {'name': 'Knitting', 'icon': Icons.checkroom},
    {'name': 'Carpentry', 'icon': Icons.handyman},
    {'name': 'Dance Instruction', 'icon': Icons.directions_run},
    {'name': 'Coding Tutoring', 'icon': Icons.computer},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF084C5C),
        title: const Text(
          'Categories',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.0,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Get.to(() => MentorsScreen(skill: categories[index]['name']));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categories[index]['icon'],
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      categories[index]['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}