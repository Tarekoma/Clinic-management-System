// ─────────────────────────────────────────────────────────────────────────────
// lib/views/auth/registration_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:Hakim/providers/auth_providers.dart';
import 'package:Hakim/viewmodels/auth_viewmodel.dart';

class _R {
  _R._();

  static const Color navy = Color(0xFF0B3D6B);
  static const Color navyDeep = Color(0xFF071E34);
  static const Color navyMid = Color(0xFF0D4F8A);
  static const Color teal = Color(0xFF00695C);
  static const Color tealDeep = Color(0xFF004D40);
  static const Color tealBg = Color(0xFFEFF7F6);
  static const Color navyBg = Color(0xFFEFF4FB);
  static const Color bgPage = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE4EAF1);
  static const Color inputBg = Color(0xFFF5F7FA);
  static const Color textH = Color(0xFF0D1B2A);
  static const Color textS = Color(0xFF546E7A);
  static const Color textM = Color(0xFF90A4AE);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFDEDED);

  static const LinearGradient gHeader = LinearGradient(
    colors: [Color(0xFF071E34), Color(0xFF0B3D6B), Color(0xFF004D40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static InputDecoration inp(
    String label, {
    Widget? pre,
    Widget? suf,
    String? hint,
    bool required = false,
  }) => InputDecoration(
    labelText: required ? '$label *' : label,
    hintText: hint,
    prefixIcon: pre,
    suffixIcon: suf,
    filled: true,
    fillColor: inputBg,
    labelStyle: const TextStyle(fontSize: 13, color: textS),
    hintStyle: const TextStyle(fontSize: 13, color: textM),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: navy, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  );

  static BoxDecoration sectionCard({double r = 18}) => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(r),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0B3D6B).withOpacity(0.07),
        blurRadius: 18,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// REGISTRATION PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specializationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // ── ADDED: doctor email field for assistant registration ─────────────────
  final _doctorEmailController = TextEditingController();

  String _selectedGender = 'MALE';
  String _selectedUserType = 'Doctor';
  String? _selectedCountry;
  String? _selectedRegion;
  String? _selectedCity;
  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _pendingApproval = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const Map<String, List<String>> _countryRegions = {
    'Egypt': ['Cairo', 'Alexandria', 'Giza', 'Luxor', 'Aswan'],
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam'],
    'UAE': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah'],
    'Jordan': ['Amman', 'Zarqa', 'Irbid', 'Aqaba', 'Madaba'],
  };
  static const Map<String, List<String>> _regionCities = {
    // Egypt
    'Cairo': ['Nasr City', 'Heliopolis', 'Maadi', 'Zamalek', 'Downtown Cairo'],
    'Alexandria': ['Smouha', 'Stanley', 'Montaza', 'Sidi Gaber', 'Miami'],
    'Giza': ['Dokki', 'Mohandessin', 'Haram', 'Faisal', '6th of October'],
    'Luxor': ['Luxor City', 'Karnak', 'New Luxor', 'West Bank', 'Esna'],
    'Aswan': ['Aswan City', 'Edfu', 'Kom Ombo', 'Abu Simbel', 'Daraw'],
    // Saudi Arabia
    'Riyadh': ['Al Olaya', 'Al Malaz', 'Al Naseem', 'Al Wurud', 'Al Sahafa'],
    'Jeddah': ['Al Balad', 'Al Hamra', 'Al Rawdah', 'Al Zahraa', 'Al Shate'],
    'Mecca': ['Al Aziziyah', 'Ajyad', 'Al Adl', 'Kudai', 'Misfalah'],
    'Medina': ['Al Anbariyah', 'Quba', 'Al Manakhah', 'Al Uyoun', 'Shoza'],
    'Dammam': ['Al Faisaliyah', 'Al Nuzha', 'Al Qusur', 'Al Badiyah', 'Al Shulah'],
    // UAE
    'Dubai': ['Downtown Dubai', 'Dubai Marina', 'JBR', 'Deira', 'Bur Dubai'],
    'Abu Dhabi': ['Al Khalidiyah', 'Al Mushrif', 'Al Reem Island', 'Khalifa City', 'Al Reef'],
    'Sharjah': ['Al Majaz', 'Al Qasimiyah', 'Al Nahda', 'Al Taawun', 'Al Khan'],
    'Ajman': ['Al Nuaimiyah', 'Al Rashidiyah', 'Al Hamidiyah', 'Al Jurf', 'Al Mowaihat'],
    'Ras Al Khaimah': ['Al Nakheel', 'Al Hamra', 'Al Qawasim Corniche', 'Mina Al Arab', 'Dafan Al Nakheel'],
    // Jordan
    'Amman': ['Abdoun', 'Sweifieh', 'Shmeisani', 'Jabal Amman', 'Khalda'],
    'Zarqa': ['Al Hashimiyyah', 'Al Russayfah', 'Al Zarqa Al Jadida', 'Al Zumur', 'New Zarqa'],
    'Irbid': ['Al Husn', 'Bani Obeid', 'Ramtha', 'Al Mazar', 'Irbid City'],
    'Aqaba': ['Al Saha', 'Al Corniche', 'Al Sharouk', 'Al Quweira', 'Wadi Rum Area'],
    'Madaba': ['Madaba City', 'Dhiban', 'Machaerus', 'Mount Nebo Area', 'Al Faysaliyyah'],
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _clinicNameController.dispose();
    _licenseController.dispose();
    _specializationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _doctorEmailController.dispose(); // ← dispose the new controller
    super.dispose();
  }

  bool get _isDoctor => _selectedUserType == 'Doctor';

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _R.navy)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd / MM / yyyy').format(picked);
      });
    }
  }

  Widget _buildPendingApprovalScreen() {
    final isDoctor = _selectedUserType == 'Doctor';
    final accentColor = isDoctor ? _R.navy : _R.teal;
    final accentBg = isDoctor ? _R.navyBg : _R.tealBg;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: accentBg, shape: BoxShape.circle),
              child: Icon(Icons.verified_rounded, size: 46, color: accentColor),
            ),
            const SizedBox(height: 28),
            Text(
              'Registration Successful',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _R.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _PendingRow(
                    icon: Icons.hourglass_top_rounded,
                    color: accentColor,
                    text: 'Your account has been created and is currently '
                        'pending administrator approval.',
                  ),
                  Divider(height: 24, color: _R.divider),
                  _PendingRow(
                    icon: Icons.notifications_active_rounded,
                    color: accentColor,
                    text: 'You will be able to sign in once your account '
                        'has been activated by an administrator.',
                  ),
                  Divider(height: 24, color: _R.divider),
                  _PendingRow(
                    icon: Icons.lock_clock_rounded,
                    color: accentColor,
                    text: 'Attempting to log in before activation will be '
                        'rejected — please wait for approval first.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  'Back to Login',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _R.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final data = RegistrationData(
      userType: _selectedUserType,
      email: _emailController.email,
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      gender: _selectedGender,
      phone: _phoneController.text.trim(),
      dateOfBirth: _selectedDob,
      country: _selectedCountry,
      region: _selectedRegion,
      city: _selectedCity,
      clinicName: _clinicNameController.text.trim(),
      specialization: _isDoctor ? _specializationController.text.trim() : null,
      licenseNumber: _isDoctor ? _licenseController.text.trim() : null,
      // ── FIXED: pass doctorEmail for assistant accounts ─────────────────
      // Without this, _createAssistant() sends no doctor_email to the backend,
      // the assistant record is created with no doctor link, and the assistant
      // can never see any patients or appointments.
      doctorEmail: !_isDoctor ? _doctorEmailController.email : null,
    );

    await ref.read(authProvider.notifier).register(data);
  }

  @override
  Widget build(BuildContext context) {
    // Only watch isLoading — prevents the entire form from rebuilding on every
    // error or registrationSuccess state change (which happens after submit).
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!next.registrationSuccess) return;
      ref.read(authProvider.notifier).clearRegistrationSuccess();
      if (mounted) setState(() => _pendingApproval = true);
    });

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.errorMessage == null) return;
      if (prev?.errorMessage == next.errorMessage) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showError(next.errorMessage!);
      });
    });

    if (_pendingApproval) {
      return Scaffold(
        backgroundColor: _R.bgPage,
        body: _buildPendingApprovalScreen(),
      );
    }

    // resizeToAvoidBottomInset: false prevents Flutter from shrinking and
    // re-laying out the entire form tree every time the keyboard opens —
    // the keyboard-aware bottom padding below handles scrolling instead.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: _R.bgPage,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 32 + bottomInset),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildTypeSelector(),
                      const SizedBox(height: 20),
                      _buildSection(
                        'Personal Information',
                        Icons.person_rounded,
                        _R.navy,
                        _R.navyBg,
                        _buildPersonalFields(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Location',
                        Icons.location_on_rounded,
                        _R.teal,
                        _R.tealBg,
                        _buildLocationFields(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Clinic Information',
                        Icons.local_hospital_rounded,
                        _R.navy,
                        _R.navyBg,
                        _buildClinicFields(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Account Credentials',
                        Icons.lock_rounded,
                        _R.teal,
                        _R.tealBg,
                        _buildCredentialsFields(),
                      ),
                      const SizedBox(height: 28),
                      _buildSubmitButton(isLoading),
                      const SizedBox(height: 12),
                      _buildSignInLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(gradient: _R.gHeader),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 18),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white70,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Join the Hakim medical portal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset('assets/icon/app_icon6.png', width: 44, height: 44),
          ],
        ),
      ),
    ),
  );

  Widget _buildTypeSelector() => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: _R.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: _R.navy.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        _TypeTab(
          label: 'Doctor',
          icon: Icons.medical_services_rounded,
          selected: _isDoctor,
          selectedColor: _R.navy,
          selectedBg: _R.navyBg,
          onTap: () => setState(() => _selectedUserType = 'Doctor'),
        ),
        _TypeTab(
          label: 'Assistant',
          icon: Icons.support_agent_rounded,
          selected: !_isDoctor,
          selectedColor: _R.teal,
          selectedBg: _R.tealBg,
          onTap: () => setState(() => _selectedUserType = 'Assistant'),
        ),
      ],
    ),
  );

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    Color bg,
    Widget content,
  ) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _R.sectionCard(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        Divider(height: 20, color: _R.divider.withOpacity(0.7)),
        content,
      ],
    ),
  );

  Widget _buildPersonalFields() => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 14, color: _R.textH),
              decoration: _R.inp(
                'First Name',
                required: true,
                pre: const Icon(Icons.person_rounded, size: 18, color: _R.textM),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 14, color: _R.textH),
              decoration: _R.inp(
                'Last Name',
                required: true,
                pre: const Icon(Icons.person_outline_rounded, size: 18, color: _R.textM),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: _pickDateOfBirth,
              style: const TextStyle(fontSize: 13, color: _R.textH),
              decoration: _R.inp(
                'Date of Birth',
                required: true,
                pre: const Icon(Icons.cake_rounded, size: 18, color: _R.textM),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              style: const TextStyle(fontSize: 13, color: _R.textH),
              decoration: _R.inp(
                'Gender',
                required: true,
                pre: const Icon(Icons.wc_rounded, size: 18, color: _R.textM),
              ),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _selectedGender = v ?? 'MALE'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 14, color: _R.textH),
        decoration: _R.inp(
          'Phone Number',
          required: true,
          hint: '+201234567890',
          pre: const Icon(Icons.phone_rounded, size: 18, color: _R.textM),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
    ],
  );

  Widget _buildLocationFields() => Column(
    children: [
      DropdownButtonFormField<String>(
        value: _selectedCountry,
        style: const TextStyle(fontSize: 13, color: _R.textH),
        decoration: _R.inp(
          'Country',
          required: true,
          pre: const Icon(Icons.flag_rounded, size: 18, color: _R.textM),
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
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _selectedRegion,
        style: const TextStyle(fontSize: 13, color: _R.textH),
        decoration: _R.inp(
          'Region',
          required: true,
          pre: const Icon(
            Icons.location_city_rounded,
            size: 18,
            color: _R.textM,
          ),
        ),
        items: _selectedCountry == null
            ? []
            : _countryRegions[_selectedCountry]!
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
        onChanged: (v) => setState(() {
          _selectedRegion = v;
          _selectedCity = null;
        }),
        validator: (v) => v == null ? 'Required' : null,
      ),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _selectedCity,
        style: const TextStyle(fontSize: 13, color: _R.textH),
        decoration: _R.inp(
          'City',
          required: true,
          pre: const Icon(Icons.location_on_rounded, size: 18, color: _R.textM),
        ),
        items:
            _selectedRegion == null ||
                !_regionCities.containsKey(_selectedRegion)
            ? []
            : _regionCities[_selectedRegion]!
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
        onChanged: (v) => setState(() => _selectedCity = v),
        validator: (v) => v == null ? 'Required' : null,
      ),
    ],
  );

  // ── Clinic fields — includes doctor email field for assistant ─────────────
  Widget _buildClinicFields() => Column(
    children: [
      TextFormField(
        controller: _clinicNameController,
        style: const TextStyle(fontSize: 14, color: _R.textH),
        decoration: _R.inp(
          'Clinic Name',
          required: true,
          pre: const Icon(
            Icons.local_hospital_outlined,
            size: 18,
            color: _R.textM,
          ),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),

      // ── Doctor-only fields ───────────────────────────────────────────
      if (_isDoctor) ...[
        const SizedBox(height: 14),
        TextFormField(
          controller: _specializationController,
          style: const TextStyle(fontSize: 14, color: _R.textH),
          decoration: _R.inp(
            'Specialization',
            required: true,
            hint: 'e.g. General Medicine, Cardiology',
            pre: const Icon(Icons.biotech_rounded, size: 18, color: _R.textM),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _licenseController,
          style: const TextStyle(fontSize: 14, color: _R.textH),
          decoration: _R.inp(
            'License Number',
            required: true,
            pre: const Icon(Icons.badge_rounded, size: 18, color: _R.textM),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],

      // ── Assistant-only: doctor email link ────────────────────────────
      // THIS IS THE ROOT CAUSE FIX.
      // The backend links an assistant to a doctor at creation time via
      // the doctor_email field.  Without this field:
      //   • _createAssistant() sends no doctor_email to the backend
      //   • The assistant record is created with no doctor_id FK
      //   • The assistant JWT has no clinic scope
      //   • Every /clinic/patients and /clinic/appointments call returns 0
      //
      // This field was missing from the form entirely — assistants could
      // register but would never see any data.
      if (!_isDoctor) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF7F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _R.teal.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: _R.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter the email address of the doctor you work for. '
                  'This links your account to their clinic so you can '
                  'see their patients and appointments.',
                  style: TextStyle(fontSize: 11, color: _R.teal, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _doctorEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14, color: _R.textH),
          decoration: _R.inp(
            "Doctor's Email",
            required: true,
            hint: 'doctor@clinic.com',
            pre: const Icon(
              Icons.medical_services_rounded,
              size: 18,
              color: _R.textM,
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return "Doctor's email is required to link your account";
            }
            if (!v.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),
      ],
    ],
  );

  Widget _buildCredentialsFields() => Column(
    children: [
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 14, color: _R.textH),
        decoration: _R.inp(
          'Email',
          required: true,
          pre: const Icon(Icons.email_rounded, size: 18, color: _R.textM),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (!v.contains('@')) return 'Invalid email';
          return null;
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(fontSize: 14, color: _R.textH),
        decoration: _R.inp(
          'Password',
          required: true,
          pre: const Icon(Icons.lock_rounded, size: 18, color: _R.textM),
          suf: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: _R.textM,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (v.length < 8) return 'Minimum 8 characters';
          return null;
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        style: const TextStyle(fontSize: 14, color: _R.textH),
        decoration: _R.inp(
          'Confirm Password',
          required: true,
          pre: const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: _R.textM,
          ),
          suf: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: _R.textM,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (v != _passwordController.text) return 'Passwords do not match';
          return null;
        },
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _R.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Password must be at least 8 characters. '
                'Use a mix of letters, numbers, and symbols for security.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildSubmitButton(bool isLoading) => SizedBox(
    width: double.infinity,
    height: 54,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDoctor
              ? [_R.navyDeep, _R.navy, _R.navyMid]
              : [_R.tealDeep, _R.teal, const Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isDoctor ? _R.navy : _R.teal).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isDoctor
                        ? Icons.medical_services_rounded
                        : Icons.support_agent_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Create $_selectedUserType Account',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );

  Widget _buildSignInLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Already have an account?',
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Sign In',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _isDoctor ? _R.navy : _R.teal,
          ),
        ),
      ),
      const SizedBox(height: 70),
    ],
  );
}

class _PendingRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _PendingRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: _R.textS,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

extension _CtrlX on TextEditingController {
  String get email => text.trim().toLowerCase();
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor, selectedBg;
  final VoidCallback onTap;
  const _TypeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: selectedColor.withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? selectedColor : _R.textM),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? selectedColor : _R.textM,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
