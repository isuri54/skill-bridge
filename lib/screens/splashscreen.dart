import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skillbridge/screens/bottomnavbar.dart';
import 'package:skillbridge/screens/loginscreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Firebase.initializeApp();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        Get.offAll(() => const BottomNavBar());
      } else {
        Get.offAll(() => const LoginScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF084C5C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('assets/images/skillbridge.png'),
              width: 200,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}