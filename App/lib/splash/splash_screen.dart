// lib/splash_screen.dart
//
// On launch:
//   • Checks secure storage for a saved token + role + user profile.
//   • If all exist   → navigate directly to DoctorInterface or AssistantInterface
//                      with the restored UserProfile (required by both interfaces).
//   • If missing     → navigate to LoginPage (first launch or after sign-out).

import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/views/assistant/assistant_interface.dart';
import 'package:Hakim/views/auths/login_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_interface.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolveStartScreen();
  }

  Future<void> _resolveStartScreen() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final token = await ApiService.getToken();
    final role = await ApiService.getRole();
    final profileMap = await ApiService.getUserProfile();

    Widget destination;

    if (token != null && role != null && profileMap != null) {
      // Reconstruct the UserProfile from the saved map
      final profile = UserProfile(
        id: profileMap['id']?.toString() ?? '',
        email: profileMap['email']?.toString() ?? '',
        username: profileMap['username']?.toString() ?? '',
        firstName: profileMap['first_name']?.toString() ?? '',
        lastName: profileMap['last_name']?.toString() ?? '',
        userType: profileMap['role']?.toString() ?? role,
        gender: profileMap['gender']?.toString() ?? '',
        birthDate: profileMap['date_of_birth'] != null
            ? DateTime.tryParse(profileMap['date_of_birth'].toString())
            : null,
        clinicName: profileMap['clinic_name']?.toString(),
        licenseNumber: profileMap['license_number']?.toString(),
        phone: profileMap['phone_number']?.toString(),
        region: profileMap['region']?.toString(),
        specialization: profileMap['specialization']?.toString(),
        createdAt: profileMap['created_at'] != null
            ? DateTime.tryParse(profileMap['created_at'].toString()) ??
                  DateTime.now()
            : DateTime.now(),
      );

      if (role == 'doctor') {
        destination = DoctorInterface(doctorProfile: profile);
      } else if (role == 'assistant') {
        destination = AssistantInterface(assistantProfile: profile);
      } else {
        // Unknown role — fall back to login
        destination = const LoginPage();
      }
    } else {
      // No session — show login
      destination = const LoginPage();
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/app_icon2.png'),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
