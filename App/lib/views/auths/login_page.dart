// ─────────────────────────────────────────────────────────────────────────────
// lib/views/auth/login_page.dart
//
// Login screen — UI only.
//
// What this file does:
//   • Renders the page (gradient background, orbs, header, form card)
//   • Owns the two TextEditingControllers and the _obscurePassword toggle
//   • Observes AuthState via ref.watch(authProvider) to react to loading,
//     errors, and successful authentication
//   • Calls vm.login() / vm.clearError() — zero ApiService calls here
//
// What this file does NOT do:
//   • No ApiService calls
//   • No JWT decoding
//   • No UserProfile construction
//   • No role resolution logic
// ─────────────────────────────────────────────────────────────────────────────

import 'package:Hakim/views/assistant/assistant_interface.dart';
import 'package:Hakim/views/auths/registration_page.dart';
import 'package:Hakim/views/doctor/doctor_pages/doctor_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Hakim/providers/auth_providers.dart';
import 'package:Hakim/viewmodels/auth_viewmodel.dart';

// ─── Design tokens (unchanged from original _L class) ────────────────────────

class _L {
  _L._();

  static const Color navy = Color(0xFF0B3D6B);
  static const Color navyDeep = Color(0xFF071E34);
  static const Color navyMid = Color(0xFF0D4F8A);
  static const Color teal = Color(0xFF00695C);
  static const Color tealDeep = Color(0xFF004D40);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE4EAF1);
  static const Color textH = Color(0xFF0D1B2A);
  static const Color textS = Color(0xFF546E7A);
  static const Color textM = Color(0xFF90A4AE);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFDEDED);

  static const LinearGradient gBg = LinearGradient(
    colors: [Color(0xFF071E34), Color(0xFF0B3D6B), Color(0xFF004D40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration cardDecor = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF071E34).withOpacity(0.32),
        blurRadius: 48,
        offset: const Offset(0, 20),
      ),
      BoxShadow(
        color: const Color(0xFF004D40).withOpacity(0.12),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static InputDecoration inp(
    String label, {
    Widget? pre,
    Widget? suf,
    String? hint,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: pre,
    suffixIcon: suf,
    filled: true,
    fillColor: const Color(0xFFF5F7FA),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Pure local UI state — no business logic
  bool _obscurePassword = true;

  // Demo-fill constants (unchanged)
  static const String _doctorEmail = 'dr.ahmed@clinic.com';
  static const String _doctorPassword = 'Doctor123!';
  static const String _assistantEmail = 'assistant@clinic.com';
  static const String _assistantPassword = 'Assist123!';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Lifecycle ───────────────────────────────────────────────────────────

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
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Navigation helper ───────────────────────────────────────────────────

  void _go(Widget page) => Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );

  // ── React to AuthState changes ──────────────────────────────────────────

  /// Called from the build method via a post-frame listener pattern.
  /// Routes the user to the correct interface once authentication succeeds.
  void _onStateChange(AuthState state) {
    if (!state.isAuthenticated || state.user == null) return;
    switch (state.destination) {
      case AuthDestination.doctor:
        _go(DoctorInterface(doctorProfile: state.user!));
      case AuthDestination.assistant:
        _go(AssistantInterface(assistantProfile: state.user!));
      case AuthDestination.none:
        break;
    }
  }

  // ── Demo fill helpers (local UI concern — no API calls) ─────────────────

  void _fillDoctor() {
    _emailController.text = _doctorEmail;
    _passwordController.text = _doctorPassword;
    ref.read(authProvider.notifier).clearError();
  }

  void _fillAssistant() {
    _emailController.text = _assistantEmail;
    _passwordController.text = _assistantPassword;
    ref.read(authProvider.notifier).clearError();
  }

  // ── Login trigger ───────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .login(_emailController.text, _passwordController.text);
    // Navigation is handled by _onStateChange via the listener below
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Observe state ──────────────────────────────────────────────────────
    final state = ref.watch(authProvider);

    // Navigate once authenticated — runs after the current frame to avoid
    // calling setState/Navigator during build.
    ref.listen<AuthState>(authProvider, (_, next) {
      // Guard: only navigate when login is FULLY complete — not mid-loading.
      // Without !next.isLoading, a stale isAuthenticated:true from a previous
      // session fires navigation the moment isLoading flips on a new login,
      // sending the new user to the previous user's interface.
      if (!next.isLoading &&
          next.isAuthenticated &&
          next.destination != AuthDestination.none) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onStateChange(next);
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(decoration: const BoxDecoration(gradient: _L.gBg)),

          // Decorative orbs (pixel-identical to original)
          Positioned(
            top: -100,
            right: -80,
            child: _Orb(size: 300, opacity: 0.03),
          ),
          Positioned(
            top: 70,
            right: 40,
            child: _OrbRing(size: 120, opacity: 0.06),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF004D40).withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 30,
            child: _OrbRing(size: 80, opacity: 0.08),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildCard(state),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header (unchanged) ───────────────────────────────────────────────────

  Widget _buildHeader() => Column(
    children: [
      Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.20), width: 1.5),
        ),
        child: const Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Hakim',
        style: TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Medical Management Portal',
        style: TextStyle(
          color: Colors.white.withOpacity(0.52),
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RolePill(
            icon: Icons.medical_services_rounded,
            label: 'Doctor',
            color: const Color(0xFF4FC3F7),
          ),
          const SizedBox(width: 12),
          _RolePill(
            icon: Icons.support_agent_rounded,
            label: 'Assistant',
            color: const Color(0xFF80CBC4),
          ),
        ],
      ),
    ],
  );

  // ── Card — receives AuthState so loading/error are driven by the VM ──────

  Widget _buildCard(AuthState state) => Container(
    decoration: _L.cardDecor,
    padding: const EdgeInsets.all(28),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_L.navy, _L.teal],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _L.textH,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(fontSize: 12, color: _L.textS),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Demo access ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _L.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 13,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Quick Demo Access',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickBtn(
                        icon: Icons.medical_services_rounded,
                        label: 'Fill Doctor',
                        fg: _L.navy,
                        bg: const Color(0xFFEFF4FB),
                        border: const Color(0xFFBFD3EC),
                        onTap: _fillDoctor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickBtn(
                        icon: Icons.support_agent_rounded,
                        label: 'Fill Assistant',
                        fg: _L.teal,
                        bg: const Color(0xFFEFF7F6),
                        border: const Color(0xFFB2DDD9),
                        onTap: _fillAssistant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Email field ──────────────────────────────────────────────
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14, color: _L.textH),
            decoration: _L.inp(
              'Email',
              pre: const Icon(Icons.email_outlined, size: 18, color: _L.textM),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
            onChanged: (_) => ref.read(authProvider.notifier).clearError(),
          ),
          const SizedBox(height: 14),

          // ── Password field ───────────────────────────────────────────
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            style: const TextStyle(fontSize: 14, color: _L.textH),
            decoration: _L.inp(
              'Password',
              pre: const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: _L.textM,
              ),
              suf: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: _L.textM,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your password';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
            onChanged: (_) => ref.read(authProvider.notifier).clearError(),
          ),

          // ── Error banner (driven by AuthState.errorMessage) ──────────
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _L.errorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _L.error.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: _L.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _L.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Forgot password ──────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: _L.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Sign In button (loading driven by AuthState.isLoading) ────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_L.navyDeep, _L.navy, _L.navyMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _L.navy.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ── Divider ──────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(child: Divider(color: _L.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[400],
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _L.divider)),
            ],
          ),

          const SizedBox(height: 20),

          // ── Create account ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistrationPage()),
              ),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text(
                'Create New Account',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _L.navy,
                side: BorderSide(color: _L.navy.withOpacity(0.35), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'Secure medical management portal',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Micro Widgets (unchanged from original) ──────────────────────────────────

class _Orb extends StatelessWidget {
  final double size, opacity;
  const _Orb({required this.size, required this.opacity, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}

class _OrbRing extends StatelessWidget {
  final double size, opacity;
  const _OrbRing({required this.size, required this.opacity, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(opacity), width: 1),
    ),
  );
}

class _RolePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RolePill({
    required this.icon,
    required this.label,
    required this.color,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg, bg, border;
  final VoidCallback onTap;
  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
    required this.onTap,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    ),
  );
}
