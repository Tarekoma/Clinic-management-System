import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // ─── Admin Credentials (used silently in background) ───────────────────────
  static const String _baseUrl = 'https://backend.hakim-app.cloud';
  static const String _apiKey =
      '66ba4126aa3b9f227adde3d1e8e143ad0076ad0fdaf861501051eabec00ccc0b';
  static const String _adminEmail = 'admin@system.com';
  static const String _adminPassword = 'admin123!';

  // ─── Form ───────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController(); // date of birth
  final _phoneController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specializationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedGender = 'male';
  String _selectedUserType = 'Doctor';
  String? _selectedCountry;
  String? _selectedRegion;
  String? _selectedCity;
  DateTime? _selectedDob;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Map<String, List<String>> _countryRegions = {
    'Egypt': ['Cairo', 'Alexandria', 'Giza', 'Luxor', 'Aswan'],
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam'],
    'UAE': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah'],
    'Jordan': ['Amman', 'Zarqa', 'Irbid', 'Aqaba', 'Madaba'],
  };

  final Map<String, List<String>> _regionCities = {
    'Cairo': ['Nasr City', 'Heliopolis', 'Maadi', 'Zamalek', 'Downtown'],
    'Alexandria': ['Miami', 'Smouha', 'Stanley', 'Montaza', 'Sidi Gaber'],
    'Riyadh': ['Al Olaya', 'Al Malaz', 'Al Naseem', 'Al Wurud', 'Al Sahafa'],
    'Dubai': ['Downtown', 'Marina', 'JBR', 'Deira', 'Bur Dubai'],
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _clinicNameController.dispose();
    _licenseController.dispose();
    _specializationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Step 1: Login as admin → get token ────────────────────────────────────
  Future<String> _getAdminToken() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json', 'X-API-KEY': _apiKey},
      body: jsonEncode({'email': _adminEmail, 'password': _adminPassword}),
    );

    if (response.statusCode != 200) {
      throw Exception('Admin login failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final token = data['access_token'] as String?;
    if (token == null) throw Exception('No access_token in response');
    return token;
  }

  // ─── Step 2: Create Doctor using admin token ────────────────────────────────
  Future<void> _createDoctor(String adminToken) async {
    final nameParts = _fullNameController.text.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '-';

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/users/doctors'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': _apiKey,
        'Authorization': 'Bearer $adminToken',
      },
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': _selectedDob != null
            ? '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}'
            : '1990-01-01',
        'gender': _selectedGender,
        'phone_number': _phoneController.text.trim(),
        'country': _selectedCountry ?? '',
        'region': _selectedRegion ?? '',
        'city': _selectedCity ?? '',
        'clinic_name': _clinicNameController.text.trim(),
        'specialization': _specializationController.text.trim().isEmpty
            ? 'General Medicine'
            : _specializationController.text.trim(),
        'license_number': _licenseController.text.trim(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create doctor: ${response.body}');
    }
  }

  // ─── Step 3: Create Assistant using admin token ─────────────────────────────
  Future<void> _createAssistant(String adminToken) async {
    final nameParts = _fullNameController.text.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '-';

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/users/assistants'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': _apiKey,
        'Authorization': 'Bearer $adminToken',
      },
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': _phoneController.text.trim(),
        'clinic_name': _clinicNameController.text.trim(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create assistant: ${response.body}');
    }
  }

  // ─── Main Register Flow ─────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get admin token silently
      final adminToken = await _getAdminToken();

      // 2. Create doctor or assistant
      if (_selectedUserType == 'Doctor') {
        await _createDoctor(adminToken);
      } else {
        await _createAssistant(adminToken);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! You can now login.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Date Picker ────────────────────────────────────────────────────────────
  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Account'),
        backgroundColor: Colors.blue[700],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Account Type ──────────────────────────────────────────────
                const Text(
                  'Account Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Doctor',
                      label: Text('Doctor'),
                      icon: Icon(Icons.medical_services),
                    ),
                    ButtonSegment(
                      value: 'Assistant',
                      label: Text('Assistant'),
                      icon: Icon(Icons.support_agent),
                    ),
                  ],
                  selected: {_selectedUserType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _selectedUserType = newSelection.first);
                  },
                ),
                const SizedBox(height: 24),

                // ── Full Name ─────────────────────────────────────────────────
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Date of Birth & Gender ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _pickDateOfBirth,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth *',
                          prefixIcon: const Icon(Icons.cake),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender *',
                          prefixIcon: const Icon(Icons.wc),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedGender = v ?? 'male'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Phone ─────────────────────────────────────────────────────
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: const Icon(Icons.phone),
                    hintText: '+201234567890',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Country ───────────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'Country *',
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _countryRegions.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedCountry = v;
                    _selectedRegion = null;
                    _selectedCity = null;
                  }),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Region ────────────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: InputDecoration(
                    labelText: 'Region *',
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _selectedCountry == null
                      ? []
                      : _countryRegions[_selectedCountry]!
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                  onChanged: (v) => setState(() {
                    _selectedRegion = v;
                    _selectedCity = null;
                  }),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── City ──────────────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'City *',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      _selectedRegion == null ||
                          !_regionCities.containsKey(_selectedRegion)
                      ? []
                      : _regionCities[_selectedRegion]!
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Clinic Name ───────────────────────────────────────────────
                TextFormField(
                  controller: _clinicNameController,
                  decoration: InputDecoration(
                    labelText: 'Clinic Name *',
                    prefixIcon: const Icon(Icons.local_hospital),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Doctor-only fields ────────────────────────────────────────
                if (_selectedUserType == 'Doctor') ...[
                  TextFormField(
                    controller: _specializationController,
                    decoration: InputDecoration(
                      labelText: 'Specialization *',
                      prefixIcon: const Icon(Icons.biotech),
                      hintText: 'e.g. General Medicine, Cardiology',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseController,
                    decoration: InputDecoration(
                      labelText: 'License Number *',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Email ─────────────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ──────────────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm Password ──────────────────────────────────────────
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Register Button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
