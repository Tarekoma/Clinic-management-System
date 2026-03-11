// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/doctor/image_upload_widget.dart
//
// Reusable widget — Camera / Gallery picker with image preview.
//
// Pure StatelessWidget. The selected image file and callbacks are owned
// by the parent (AIImagingTab → consultation_page.dart).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Hakim/utils/doctor_theme.dart';

typedef _T = DoctorTheme;

class ImageUploadWidget extends StatelessWidget {
  /// The currently selected image file, or null if none picked yet.
  final File? selectedImage;

  /// Called when the user taps Camera or Gallery.
  final Future<void> Function(ImageSource source) onPickImage;

  const ImageUploadWidget({
    required this.selectedImage,
    required this.onPickImage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Picker buttons ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _PickerButton(
                label: 'Camera',
                icon: Icons.camera_alt_rounded,
                onTap: () => onPickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickerButton(
                label: 'Gallery',
                icon: Icons.photo_library_rounded,
                onTap: () => onPickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),

        // ── Image preview ──────────────────────────────────────────────────
        if (selectedImage != null) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Image.file(
                  selectedImage!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
                // Small "replace" label hint
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tap buttons to replace',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // ── Empty state placeholder ───────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: _T.bgInput,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _T.navy.withOpacity(0.15),
                width: 1.5,
                style: BorderStyle.none, // replaced visually with dashes below
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 36,
                  color: _T.textM.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No image selected',
                  style: TextStyle(
                    fontSize: 13,
                    color: _T.textM.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Private: single picker button ─────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _T.bgInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.navy.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: _T.navy),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _T.textH,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
