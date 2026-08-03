import 'package:flutter/foundation.dart';
import 'package:Hakim/errors/error_handler.dart';
import 'package:Hakim/services/API_Service.dart';

/// Shared static helpers used by both DoctorViewModel and AssistantViewModel.
///
/// Extracted to eliminate verbatim duplication across the two classes.
class ClinicHelpers {
  const ClinicHelpers._();

  // ── Date helpers ─────────────────────────────────────────────────────────────

  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Formats a DateTime as a local ISO 8601 string with timezone offset,
  /// e.g. "2024-01-15T14:30:00+02:00". The backend requires local time with
  /// an explicit offset — UTC-Z format ("...Z") is rejected with a 422 error.
  static String toIso8601WithTz(DateTime dt) {
    final local = dt.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hh = offset.inHours.abs().toString().padLeft(2, '0');
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$y-$mo-${d}T$h:$mi:$s$sign$hh:$mm';
  }

  // ── Error helper ─────────────────────────────────────────────────────────────

  /// Returns a user-friendly error message. Delegates to [ErrorHandler].
  static String extractError(Object e) => ErrorHandler.friendlyMessage(e);

  // ── Chronic condition helpers ────────────────────────────────────────────────

  /// Extracts CHRONIC condition assignment objects from a PatientResponse map.
  /// Handles both flattened ({ name, category, condition_id }) and nested
  /// ({ condition: { name, category }, condition_id }) response shapes.
  static List<Map<String, dynamic>> extractChronicConditions(
    Map<String, dynamic> patient,
  ) {
    final raw = patient['patient_conditions'];
    if (raw is! List) return [];
    final result = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final cat =
          (item['category'] ??
                  (item['condition'] as Map?)?['category'] ??
                  '')
              .toString()
              .toUpperCase();
      if (cat == 'CHRONIC') {
        result.add(Map<String, dynamic>.from(item));
      }
    }
    return result;
  }

  static String conditionName(Map<String, dynamic> c) =>
      (c['name'] ?? (c['condition'] as Map?)?['name'] ?? '').toString();

  // ── Vitals helpers ───────────────────────────────────────────────────────────

  static bool hasVitals(Map<String, dynamic> v) =>
      v['blood_pressure'] != null ||
      v['heart_rate'] != null ||
      v['temperature'] != null ||
      v['weight'] != null ||
      v['height'] != null;

  static Map<String, dynamic> visitToVitals(Map<String, dynamic> visit) {
    final bp = (visit['blood_pressure'] ?? '').toString().trim();
    final parts = bp.isNotEmpty ? bp.split('/') : <String>[];
    return {
      'blood_pressure_systolic': parts.isNotEmpty ? parts[0].trim() : null,
      'blood_pressure_diastolic': parts.length > 1 ? parts[1].trim() : null,
      'heart_rate': visit['heart_rate'],
      'temperature': visit['temperature'],
      'weight': visit['weight'],
      'height': visit['height'],
      'chief_complaint': visit['chief_complaint'],
      'notes': visit['notes'],
      'recorded_at': visit['updated_at'] ?? visit['created_at'],
      'created_at': visit['created_at'],
    };
  }

  // ── Chronic condition sync ───────────────────────────────────────────────────

  /// Syncs a patient's chronic conditions to match [newDiseaseNames].
  ///
  /// [patients] is the current in-memory patients list so the method can look
  /// up existing conditions without an extra network call.
  static Future<void> syncPatientConditions({
    required int patientId,
    required List<String> newDiseaseNames,
    required List<Map<String, dynamic>> patients,
  }) async {
    var catalog = List<Map<String, dynamic>>.from(
      await ApiService.getConditions(),
    );

    // Fetch by ID so patient_conditions is present (the list endpoint may omit it).
    Map<String, dynamic> patient;
    try {
      patient = await ApiService.getPatientById(patientId);
    } catch (_) {
      patient = patients.firstWhere(
        (p) => p['id'].toString() == patientId.toString(),
        orElse: () => {},
      );
    }
    final currentConditions = extractChronicConditions(patient);
    final currentNamesLower =
        currentConditions.map((c) => conditionName(c).toLowerCase()).toSet();
    final newNamesLower = newDiseaseNames.map((n) => n.toLowerCase()).toSet();

    final toAdd = newDiseaseNames
        .where((n) => !currentNamesLower.contains(n.toLowerCase()))
        .toList();
    final toRemove = currentConditions
        .where((c) => !newNamesLower.contains(conditionName(c).toLowerCase()))
        .toList();

    for (final c in toRemove) {
      final condId = int.tryParse(
            (c['condition_id'] ??
                    (c['condition'] as Map?)?['id'] ??
                    0)
                .toString(),
          ) ??
          0;
      if (condId > 0) {
        try {
          await ApiService.removeCondition(patientId, condId);
        } catch (e) {
          debugPrint('⚠️ syncPatientConditions: removeCondition($patientId, $condId) failed: $e');
        }
      }
    }

    for (final name in toAdd) {
      Map<String, dynamic>? match;
      for (final c in catalog) {
        if ((c['name'] ?? '').toString().toLowerCase() ==
            name.toLowerCase()) {
          match = c;
          break;
        }
      }
      if (match == null) {
        for (final c in catalog) {
          final cn = (c['name'] ?? '').toString().toLowerCase();
          if (cn.contains(name.toLowerCase()) ||
              name.toLowerCase().contains(cn)) {
            match = c;
            break;
          }
        }
      }
      if (match == null || match['id'] == null) {
        try {
          match = await ApiService.createCondition(name, 'CHRONIC');
          catalog.add(match);
        } catch (e) {
          debugPrint('⚠️ syncPatientConditions: createCondition("$name") failed: $e — retrying with search');
          try {
            final found = List<Map<String, dynamic>>.from(
              await ApiService.getConditions(search: name),
            );
            if (found.isNotEmpty) match = found.first;
          } catch (e2) {
            debugPrint('⚠️ syncPatientConditions: getConditions(search:"$name") also failed: $e2');
          }
        }
      }
      if (match != null && match['id'] != null) {
        try {
          await ApiService.assignCondition(
            patientId,
            int.parse(match['id'].toString()),
            '',
          );
        } catch (e) {
          debugPrint('⚠️ syncPatientConditions: assignCondition($patientId, ${match['id']}) failed: $e');
        }
      }
    }
  }
}
