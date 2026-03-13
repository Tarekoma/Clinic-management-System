// ─────────────────────────────────────────────────────────────────────────────
// lib/views/doctor/consultation/ai_imaging_tab.dart
//
// Tab 3 — AI Imaging (X-ray / Skin disease analysis).
//
// Sections:
//   1. Image Upload   — Camera / Gallery picker + image preview
//   2. AI Analysis    — "Analyze Image" button (placeholder — AI not connected)
//   3. Result Area    — AIAnalysisResultWidget (placeholder until backend ready)
//
// Pure StatelessWidget. All state lives in consultation_page.dart and is
// passed in via constructor. The real AI analysis will be wired in later
// once the backend service is available.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Hakim/utils/doctor_theme.dart';
import 'package:Hakim/widgets/doctor/doctor_consultation_widgets.dart';
import 'package:Hakim/widgets/doctor/image_upload_widget.dart';
import 'package:Hakim/widgets/doctor/ai_analysis_result_widget.dart';

typedef _T = DoctorTheme;

class AIImagingTab extends StatelessWidget {
  // ── State snapshot (owned by parent) ──────────────────────────────────────

  /// Currently selected image file. Null if none picked.
  final File? selectedImage;

  /// Whether the AI analysis is in progress (reserved for future use).
  final bool analysisLoading;

  /// The AI result string. Null = no analysis yet (placeholder shown).
  final String? analysisResult;

  // ── Callbacks ─────────────────────────────────────────────────────────────

  /// Called when the user picks Camera or Gallery.
  /// Parent stores the file and rebuilds.
  final Future<void> Function(ImageSource source) onPickImage;

  /// Called when "Analyze Image" is tapped.
  /// Currently shows a placeholder snackbar — real AI logic added later.
  final VoidCallback onAnalyze;

  const AIImagingTab({
    required this.selectedImage,
    required this.analysisLoading,
    required this.analysisResult,
    required this.onPickImage,
    required this.onAnalyze,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header banner ──────────────────────────────────────────
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
                      const Text(
                        'AI Medical Imaging',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'X-ray & skin disease detection',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // "Coming Soon" badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── SECTION 1: Image Upload ────────────────────────────────────────
          DoctorConsultCard(
            title: 'Image Upload',
            icon: Icons.upload_file_rounded,
            child: ImageUploadWidget(
              selectedImage: selectedImage,
              onPickImage: onPickImage,
            ),
          ),

          const SizedBox(height: 14),

          // ── SECTION 2: AI Analysis ─────────────────────────────────────────
          DoctorConsultCard(
            title: 'AI Analysis',
            icon: Icons.psychology_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFCC02).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFFF57C00),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI image analysis service is not connected yet. '
                          'The button below is a placeholder for the upcoming backend integration.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6D4C00),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Analyze button (placeholder)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    // Disabled when no image is selected or when loading
                    onPressed: (selectedImage == null || analysisLoading)
                        ? null
                        : onAnalyze,
                    icon: analysisLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.image_search_rounded, size: 18),
                    label: Text(
                      analysisLoading ? 'Analyzing...' : 'Analyze Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.navy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _T.navy.withOpacity(0.35),
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
                  const Center(
                    child: Text(
                      'Select an image above to enable analysis',
                      style: TextStyle(fontSize: 11, color: _T.textS),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── SECTION 3: Result Area ─────────────────────────────────────────
          DoctorConsultCard(
            title: 'Analysis Result',
            icon: Icons.analytics_outlined,
            child: AIAnalysisResultWidget(
              result: analysisResult,
              isLoading: analysisLoading,
            ),
          ),
        ],
      ),
    );
  }
}
