import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Hakim/l10n/generated/app_localizations.dart';
import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_consultation_widgets.dart';
import 'package:Hakim/widgets/doctor/image_upload_widget.dart';

typedef _T = DoctorTheme;

class AIImagingTab extends StatelessWidget {
  final File? selectedImage;
  final Future<void> Function(ImageSource source) onPickImage;
  final VoidCallback onAnalyze;
  final String selectedImageType;
  final void Function(String type) onImageTypeChanged;

  const AIImagingTab({
    required this.selectedImage,
    required this.onPickImage,
    required this.onAnalyze,
    required this.selectedImageType,
    required this.onImageTypeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).extension<DoctorThemeData>()!;
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header banner ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _T.gradCard(),
            child: Row(
              children: [
                const Icon(
                  Icons.biotech_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.aiMedicalImaging,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        loc.xrayAndSkinDetection,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── SECTION 1: Image Upload ──────────────────────────────────────
          DoctorConsultCard(
            title: loc.imageUploadTitle,
            icon: Icons.upload_file_rounded,
            child: ImageUploadWidget(
              selectedImage: selectedImage,
              onPickImage: onPickImage,
            ),
          ),

          const SizedBox(height: 14),

          // ── Image type selector ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onImageTypeChanged('XRAY'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedImageType == 'XRAY' ? _T.navy : dt.bgInput,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedImageType == 'XRAY'
                            ? _T.navy
                            : dt.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monitor_heart_rounded,
                          size: 16,
                          color: selectedImageType == 'XRAY'
                              ? Colors.white
                              : dt.textS,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.xray,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedImageType == 'XRAY'
                                ? Colors.white
                                : dt.textS,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onImageTypeChanged('SKIN'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedImageType == 'SKIN' ? _T.navy : dt.bgInput,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedImageType == 'SKIN'
                            ? _T.navy
                            : dt.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.face_rounded,
                          size: 16,
                          color: selectedImageType == 'SKIN'
                              ? Colors.white
                              : dt.textS,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.skin,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedImageType == 'SKIN'
                                ? Colors.white
                                : dt.textS,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── SECTION 2: AI Analysis ───────────────────────────────────────
          DoctorConsultCard(
            title: loc.aiAnalysisTitle,
            icon: Icons.psychology_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _T.tealPale,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _T.teal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: _T.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.imagingInfoNotice,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.teal,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: selectedImage == null ? null : onAnalyze,
                    icon: const Icon(Icons.image_search_rounded, size: 18),
                    label: Text(loc.analyzeImage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.navy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _T.navy.withValues(alpha: 0.35),
                      disabledForegroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                if (selectedImage == null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      loc.selectImageToEnable,
                      style: TextStyle(fontSize: 11, color: dt.textS),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
