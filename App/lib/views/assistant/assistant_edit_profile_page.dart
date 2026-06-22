// ─────────────────────────────────────────────────────────────────────────────
// lib/views/assistant/assistant_edit_profile_page.dart
//
// Full-screen edit page for the assistant's own profile.
// Pushed from the profile sub-sheet in AssistantSettings; pops with the
// updated UserProfile on success.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/model/UserProfile.dart';
import 'package:Hakim/services/API_Service.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/viewmodels/auth_viewmodel.dart';

typedef _T = AssistantTheme;

class AssistantEditProfilePage extends StatefulWidget {
  final UserProfile profile;
  const AssistantEditProfilePage({required this.profile, super.key});

  @override
  State<AssistantEditProfilePage> createState() =>
      _AssistantEditProfilePageState();
}

class _AssistantEditProfilePageState extends State<AssistantEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _clinicNameCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.profile.firstName);
    _lastNameCtrl = TextEditingController(text: widget.profile.lastName);
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
    _clinicNameCtrl = TextEditingController(
      text: widget.profile.clinicName ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _clinicNameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validateMin2(String? v) {
    if ((v ?? '').trim().length < 2) {
      return AppLocalizations.of(context).minTwoCharsRequired;
    }
    return null;
  }

  String? _validatePhone(String? v) {
    final trimmed = (v ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(trimmed)) {
      return AppLocalizations.of(context).phoneNumberInvalid;
    }
    return null;
  }

  String? _validateClinic(String? v) {
    if ((v ?? '').trim().length < 2) {
      return AppLocalizations.of(context).minTwoCharsRequired;
    }
    return null;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final id = int.tryParse(widget.profile.id) ?? 0;
      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final clinicName = _clinicNameCtrl.text.trim();

      await ApiService.updateAssistant(id, {
        'first_name': firstName,
        'last_name': lastName,
        if (phone.isNotEmpty) 'phone_number': phone,
        if (clinicName.isNotEmpty) 'clinic_name': clinicName,
      });

      final newProfile = UserProfile(
        id: widget.profile.id,
        email: widget.profile.email,
        username: widget.profile.username,
        firstName: firstName,
        lastName: lastName,
        userType: widget.profile.userType,
        gender: widget.profile.gender,
        birthDate: widget.profile.birthDate,
        clinicName: clinicName.isEmpty ? widget.profile.clinicName : clinicName,
        licenseNumber: widget.profile.licenseNumber,
        phone: phone.isEmpty ? widget.profile.phone : phone,
        region: widget.profile.region,
        specialization: widget.profile.specialization,
        createdAt: widget.profile.createdAt,
        doctorId: widget.profile.doctorId,
        doctorEmail: widget.profile.doctorEmail,
      );

      await ApiService.saveUserProfile({
        'id': newProfile.id,
        'email': newProfile.email,
        'username': newProfile.username,
        'first_name': newProfile.firstName,
        'last_name': newProfile.lastName,
        'role': newProfile.userType,
        'gender': newProfile.gender,
        'date_of_birth': newProfile.birthDate?.toIso8601String(),
        'clinic_name': newProfile.clinicName,
        'license_number': newProfile.licenseNumber,
        'phone_number': newProfile.phone,
        'region': newProfile.region,
        'specialization': newProfile.specialization,
        'created_at': newProfile.createdAt.toIso8601String(),
        if (newProfile.doctorId != null) 'doctor_id': newProfile.doctorId,
        if (newProfile.doctorEmail != null)
          'doctor_email': newProfile.doctorEmail,
      });

      AuthViewModel.updateUser(newProfile);

      if (!mounted) return;
      Navigator.pop(context, newProfile);
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.profileUpdateFailed(ApiService.extractError(e))),
          backgroundColor: _T.urgent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: at.bgPage,
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: _T.gGreen),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white70,
                      ),
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        loc.editProfile,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_saving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _save,
                        child: Text(
                          loc.save,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      loc.personalInformation,
                      Icons.person_rounded,
                      at,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _firstNameCtrl,
                      enabled: !_saving,
                      decoration: _T.inpOf(
                        context,
                        loc.firstNameLabel,
                        pre: Icon(
                          Icons.badge_rounded,
                          size: 18,
                          color: at.textM,
                        ),
                      ),
                      validator: _validateMin2,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _lastNameCtrl,
                      enabled: !_saving,
                      decoration: _T.inpOf(
                        context,
                        loc.lastNameLabel,
                        pre: Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: at.textM,
                        ),
                      ),
                      validator: _validateMin2,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _phoneCtrl,
                      enabled: !_saving,
                      keyboardType: TextInputType.phone,
                      decoration: _T.inpOf(
                        context,
                        loc.phoneNumberLabel,
                        pre: Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: at.textM,
                        ),
                      ),
                      validator: _validatePhone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),

                    _sectionHeader(
                      loc.clinicLabel,
                      Icons.local_hospital_rounded,
                      at,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _clinicNameCtrl,
                      enabled: !_saving,
                      decoration: _T.inpOf(
                        context,
                        loc.clinicLabel,
                        pre: Icon(
                          Icons.local_hospital_rounded,
                          size: 18,
                          color: at.textM,
                        ),
                      ),
                      validator: _validateClinic,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _T.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                loc.save,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, AssistantThemeData at) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _T.green),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: at.textH,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
