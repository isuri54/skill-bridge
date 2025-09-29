import 'package:flutter/material.dart';
import 'package:skillbridge/screens/chathomescreen.dart';
import 'package:skillbridge/screens/homescreen.dart';
import 'package:skillbridge/screens/profilescreen.dart';
import 'package:skillbridge/screens/schedulesscreen.dart';
import 'package:skillbridge/screens/settingsscreen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {

  int selectedIndex = 0;
  List screenList = [
    const HomeScreen(),
    const SchedulesScreen(),
    const ChatsHomeScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screenList.elementAt(selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: const Color.fromARGB(255, 125, 123, 123).withOpacity(0.5),
        selectedItemColor: Color(0xFF084C5C),
        selectedLabelStyle: TextStyle(
          color: Color(0xFF084C5C),
        ),
        selectedIconTheme: IconThemeData(
          color: Color(0xFF084C5C),
        ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Schedules"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ]),
    );
  }
}