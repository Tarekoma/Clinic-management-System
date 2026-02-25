import 'dart:convert';
import 'package:Hakim/Doctor_Interface.dart';
import 'package:Hakim/api_service.dart';
import 'package:flutter/material.dart';
import 'package:Hakim/Assistant%20Interface.dart';
import 'package:Hakim/Registration%20Page.dart';
import 'package:Hakim/UserProfile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // ── Demo Credentials ──────────────────────────────────────────────────────
  static const String _doctorEmail = 'dr.ahmed@clinic.com';
  static const String _doctorPassword = 'Doctor123!';
  static const String _assistantEmail = 'assistant@clinic.com';
  static const String _assistantPassword = 'Assist123!';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDoctor() {
    setState(() {
      _emailController.text = _doctorEmail;
      _passwordController.text = _doctorPassword;
    });
  }

  void _fillAssistant() {
    setState(() {
      _emailController.text = _assistantEmail;
      _passwordController.text = _assistantPassword;
    });
  }

  // ── Decode JWT to extract user_id and role ────────────────────────────────
  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      String payload = parts[1];
      // Fix base64 padding
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print('JWT decode error: $e');
      return {};
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // ── Step 1: Login → get token ─────────────────────────────────────────
      final result = await ApiService.login(email, password);
      final token = result['access_token'] as String;
      await ApiService.saveToken(token);

      // ── Step 2: Decode JWT to get role and user_id ────────────────────────
      final payload = _decodeJwt(token);
      print('JWT PAYLOAD: $payload');

      // JWT typically contains: sub (user_id), role, exp, etc.
      // Try common JWT field names
      final role =
          (payload['role'] ?? payload['user_role'] ?? payload['type'] ?? '')
              .toString()
              .toLowerCase();

      final userId =
          (payload['sub'] ?? payload['user_id'] ?? payload['id'] ?? 0);

      print('ROLE: $role, USER_ID: $userId');

      // ── Step 3: Fetch full profile based on role ──────────────────────────
      Map<String, dynamic> user = {};

      try {
        if (role == 'doctor') {
          // Get list of doctors and find by email (since we may not know the profile ID)
          final doctors = await ApiService.getDoctors();
          final match = doctors.firstWhere(
            (d) => d['email'] == email,
            orElse: () => {},
          );
          if (match.isNotEmpty) user = Map<String, dynamic>.from(match);
        } else if (role == 'assistant') {
          final assistants = await ApiService.getAssistants();
          final match = assistants.firstWhere(
            (a) => a['email'] == email,
            orElse: () => {},
          );
          if (match.isNotEmpty) user = Map<String, dynamic>.from(match);
        }
      } catch (e) {
        print('Profile fetch error: $e');
        // If profile fetch fails, build minimal profile from JWT
      }

      print('USER PROFILE: $user');

      // ── Step 4: Build UserProfile ─────────────────────────────────────────
      final userProfile = UserProfile(
        id: (user['user_id'] ?? user['id'] ?? userId).toString(),
        email: user['email'] ?? email,
        username: user['username'] ?? email.split('@')[0],
        fullName: '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
            .trim(),
        userType: user['role'] ?? role,
        gender: user['gender'] ?? '',
        birthDate: user['date_of_birth'] != null
            ? DateTime.tryParse(user['date_of_birth'].toString())
            : null,
        clinicName: user['clinic_name'],
        licenseNumber: user['license_number'],
        createdAt: user['created_at'] != null
            ? DateTime.tryParse(user['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

      if (!mounted) return;

      // ── Step 5: Navigate based on role ───────────────────────────────────
      if (role == 'doctor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DoctorInterface(doctorProfile: userProfile),
          ),
        );
      } else if (role == 'assistant') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AssistantInterface(assistantProfile: userProfile),
          ),
        );
      } else {
        // Role not found in JWT — try email-based detection as fallback
        print('Role not found in JWT, trying email-based detection...');
        _navigateByEmail(email, userProfile);
      }
    } catch (e) {
      if (!mounted) return;
      print('LOGIN ERROR: $e');

      String message = 'Login failed. Check your credentials.';
      if (e.toString().contains('401') || e.toString().contains('403')) {
        message = 'Invalid email or password.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('connection')) {
        message = 'No internet connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fallback: detect role by trying to find user in doctors/assistants list
  void _navigateByEmail(String email, UserProfile profile) async {
    try {
      final doctors = await ApiService.getDoctors();
      final isDoctor = doctors.any((d) => d['email'] == email);

      if (!mounted) return;

      if (isDoctor) {
        final doctorData = doctors.firstWhere((d) => d['email'] == email);
        final updatedProfile = UserProfile(
          id: (doctorData['user_id'] ?? doctorData['id'] ?? profile.id)
              .toString(),
          email: doctorData['email'] ?? email,
          username: doctorData['username'] ?? email.split('@')[0],
          fullName:
              '${doctorData['first_name'] ?? ''} ${doctorData['last_name'] ?? ''}'
                  .trim(),
          userType: 'doctor',
          gender: doctorData['gender'] ?? '',
          birthDate: doctorData['date_of_birth'] != null
              ? DateTime.tryParse(doctorData['date_of_birth'].toString())
              : null,
          clinicName: doctorData['clinic_name'],
          licenseNumber: doctorData['license_number'],
          createdAt: doctorData['created_at'] != null
              ? DateTime.tryParse(doctorData['created_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DoctorInterface(doctorProfile: updatedProfile),
          ),
        );
        return;
      }

      // Try assistants
      final assistants = await ApiService.getAssistants();
      final isAssistant = assistants.any((a) => a['email'] == email);

      if (!mounted) return;

      if (isAssistant) {
        final assistantData = assistants.firstWhere((a) => a['email'] == email);
        final updatedProfile = UserProfile(
          id: (assistantData['user_id'] ?? assistantData['id'] ?? profile.id)
              .toString(),
          email: assistantData['email'] ?? email,
          username: assistantData['username'] ?? email.split('@')[0],
          fullName:
              '${assistantData['first_name'] ?? ''} ${assistantData['last_name'] ?? ''}'
                  .trim(),
          userType: 'assistant',
          gender: assistantData['gender'] ?? '',
          birthDate: assistantData['date_of_birth'] != null
              ? DateTime.tryParse(assistantData['date_of_birth'].toString())
              : null,
          clinicName: assistantData['clinic_name'],
          licenseNumber: null,
          createdAt: assistantData['created_at'] != null
              ? DateTime.tryParse(assistantData['created_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                AssistantInterface(assistantProfile: updatedProfile),
          ),
        );
        return;
      }

      // Truly unknown role
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unknown account role. Contact support.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Fallback navigation error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not determine account type. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[700]!, Colors.blue[500]!, Colors.green[500]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo ────────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[700]!, Colors.green[700]!],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Medical Portal',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Demo Accounts Box ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Demo Accounts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _fillDoctor,
                                    icon: const Icon(
                                      Icons.medical_services,
                                      size: 16,
                                    ),
                                    label: const Text('Fill Doctor'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue[700],
                                      side: BorderSide(
                                        color: Colors.blue[300]!,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _fillAssistant,
                                    icon: const Icon(
                                      Icons.support_agent,
                                      size: 16,
                                    ),
                                    label: const Text('Fill Assistant'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green[700],
                                      side: BorderSide(
                                        color: Colors.green[300]!,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Email ────────────────────────────────────────────
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Enter your email';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Password ─────────────────────────────────────────
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[600],
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Enter your password';
                            if (v.length < 6)
                              return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // ── Forgot Password ──────────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── Login Button ─────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Register Button ──────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegistrationPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text(
                              'Create New Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue[700],
                              side: BorderSide(
                                color: Colors.blue[700]!,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildUserTypeBadge(
                              'Doctor',
                              Icons.medical_services,
                              Colors.blue[700]!,
                            ),
                            const SizedBox(width: 16),
                            _buildUserTypeBadge(
                              'Assistant',
                              Icons.support_agent,
                              Colors.green[700]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
