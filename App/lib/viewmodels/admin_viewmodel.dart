// lib/viewmodels/admin_viewmodel.dart

import 'package:Hakim/services/API_Service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODELS
// ══════════════════════════════════════════════════════════════════════════════

class AdminStats {
  final int totalPatients;
  final int totalDoctors;
  final int totalAssistants;
  final int totalAdmins;
  final int activeUsers;
  final int inactiveUsers;

  const AdminStats({
    this.totalPatients = 0,
    this.totalDoctors = 0,
    this.totalAssistants = 0,
    this.totalAdmins = 0,
    this.activeUsers = 0,
    this.inactiveUsers = 0,
  });
}

class AdminUser {
  final int id;
  // The users-table PK needed by PATCH /api/v1/users/users/:id/status.
  // Doctor/assistant records expose their own profile-table PK as `id` and
  // the users-table FK as `user_id`.  These two values diverge for accounts
  // that were not the very first ones created, which is why status updates
  // silently fail for most real accounts when only `id` is used.
  final int? userId;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final String? phone;
  final String? clinicName;
  final String? specialization;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    this.phone,
    this.clinicName,
    this.specialization,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  /// The ID to pass to the status-update endpoint.
  int get statusUpdateId => userId ?? id;

  factory AdminUser.fromMap(Map<String, dynamic> m, String role) {
    return AdminUser(
      id: (m['id'] ?? 0) as int,
      userId: m['user_id'] == null ? null : (m['user_id'] as num).toInt(),
      email: m['email']?.toString() ?? '',
      firstName: m['first_name']?.toString() ?? '',
      lastName: m['last_name']?.toString() ?? '',
      role: m['role']?.toString() ?? role,
      isActive: m['is_active'] as bool? ?? false,
      phone: m['phone_number']?.toString(),
      clinicName: m['clinic_name']?.toString(),
      specialization: m['specialization']?.toString(),
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AuditLog {
  final int id;
  final String userEmail;
  final String action;
  final String? description;
  final DateTime timestamp;
  final String? resourceType;
  final String? resourceId;

  const AuditLog({
    required this.id,
    required this.userEmail,
    required this.action,
    this.description,
    required this.timestamp,
    this.resourceType,
    this.resourceId,
  });

  factory AuditLog.fromMap(Map<String, dynamic> m) {
    final rawTs =
        m['timestamp'] ?? m['created_at'] ?? m['action_time'] ?? m['time'];
    return AuditLog(
      id: (m['id'] ?? 0) as int,
      userEmail:
          m['user_email']?.toString() ??
          m['email']?.toString() ??
          m['actor_email']?.toString() ??
          m['performed_by']?.toString() ??
          m['user']?['email']?.toString() ??
          m['actor']?.toString() ??
          'Unknown',
      action: m['action']?.toString() ?? m['action_type']?.toString() ?? '',
      description:
          m['description']?.toString() ??
          m['details']?.toString() ??
          m['message']?.toString(),
      timestamp: rawTs != null
          ? DateTime.tryParse(rawTs.toString()) ?? DateTime.now()
          : DateTime.now(),
      resourceType:
          m['entity_type']?.toString() ??
          m['resource_type']?.toString() ??
          m['entity']?.toString(),
      resourceId:
          m['entity_id']?.toString() ??
          m['resource_id']?.toString(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class AdminState {
  final bool isLoadingStats;
  final String? statsError;
  final AdminStats? stats;

  final bool isLoadingUsers;
  final String? usersError;
  final List<AdminUser> doctors;
  final List<AdminUser> assistants;
  final List<AdminUser> admins;
  final String searchQuery;
  final String? roleFilter;
  final String? statusFilter;

  final bool isLoadingLogs;
  final String? logsError;
  final List<AuditLog> auditLogs;
  final bool logsHasMore;
  final int logsPage;
  final String? logsActionFilter;
  final String? logsStartDate;
  final String? logsEndDate;

  const AdminState({
    this.isLoadingStats = false,
    this.statsError,
    this.stats,
    this.isLoadingUsers = false,
    this.usersError,
    this.doctors = const [],
    this.assistants = const [],
    this.admins = const [],
    this.searchQuery = '',
    this.roleFilter,
    this.statusFilter,
    this.isLoadingLogs = false,
    this.logsError,
    this.auditLogs = const [],
    this.logsHasMore = true,
    this.logsPage = 0,
    this.logsActionFilter,
    this.logsStartDate,
    this.logsEndDate,
  });

  List<AdminUser> get allUsers => [...doctors, ...assistants, ...admins];

  List<AdminUser> get filteredUsers {
    var list = allUsers;

    if (roleFilter != null && roleFilter!.isNotEmpty) {
      list = list.where((u) => u.role.toLowerCase() == roleFilter!.toLowerCase()).toList();
    }
    if (statusFilter == 'active') {
      list = list.where((u) => u.isActive).toList();
    } else if (statusFilter == 'inactive') {
      list = list.where((u) => !u.isActive).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((u) {
        return u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            (u.clinicName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }

  AdminState copyWith({
    bool? isLoadingStats,
    String? statsError,
    bool clearStatsError = false,
    AdminStats? stats,
    bool? isLoadingUsers,
    String? usersError,
    bool clearUsersError = false,
    List<AdminUser>? doctors,
    List<AdminUser>? assistants,
    List<AdminUser>? admins,
    String? searchQuery,
    String? roleFilter,
    bool clearRoleFilter = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    bool? isLoadingLogs,
    String? logsError,
    bool clearLogsError = false,
    List<AuditLog>? auditLogs,
    bool? logsHasMore,
    int? logsPage,
    String? logsActionFilter,
    bool clearLogsActionFilter = false,
    String? logsStartDate,
    bool clearLogsStartDate = false,
    String? logsEndDate,
    bool clearLogsEndDate = false,
  }) {
    return AdminState(
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      statsError: clearStatsError ? null : statsError ?? this.statsError,
      stats: stats ?? this.stats,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      usersError: clearUsersError ? null : usersError ?? this.usersError,
      doctors: doctors ?? this.doctors,
      assistants: assistants ?? this.assistants,
      admins: admins ?? this.admins,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: clearRoleFilter ? null : roleFilter ?? this.roleFilter,
      statusFilter:
          clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      isLoadingLogs: isLoadingLogs ?? this.isLoadingLogs,
      logsError: clearLogsError ? null : logsError ?? this.logsError,
      auditLogs: auditLogs ?? this.auditLogs,
      logsHasMore: logsHasMore ?? this.logsHasMore,
      logsPage: logsPage ?? this.logsPage,
      logsActionFilter:
          clearLogsActionFilter
              ? null
              : logsActionFilter ?? this.logsActionFilter,
      logsStartDate:
          clearLogsStartDate ? null : logsStartDate ?? this.logsStartDate,
      logsEndDate: clearLogsEndDate ? null : logsEndDate ?? this.logsEndDate,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VIEWMODEL
// ══════════════════════════════════════════════════════════════════════════════

class AdminViewModel extends StateNotifier<AdminState> {
  AdminViewModel() : super(const AdminState());

  static const int _pageSize = 50;

  // ── Dashboard ──────────────────────────────────────────────────────────────

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoadingStats: true, clearStatsError: true);
    try {
      // Try dedicated endpoint first; fall back to aggregating existing ones.
      AdminStats stats;
      try {
        final raw = await ApiService.getDashboardStats();
        stats = AdminStats(
          totalPatients: (raw['total_patients'] ?? raw['patients'] ?? 0) as int,
          totalDoctors: (raw['total_doctors'] ?? raw['doctors'] ?? 0) as int,
          totalAssistants:
              (raw['total_assistants'] ?? raw['assistants'] ?? 0) as int,
          totalAdmins: (raw['total_admins'] ?? raw['admins'] ?? 0) as int,
          activeUsers: (raw['active_users'] ?? raw['active'] ?? 0) as int,
          inactiveUsers:
              (raw['inactive_users'] ?? raw['inactive'] ?? 0) as int,
        );
      } catch (_) {
        stats = await _aggregateStats();
      }
      state = state.copyWith(isLoadingStats: false, stats: stats);
    } catch (e) {
      state = state.copyWith(
        isLoadingStats: false,
        statsError: ApiService.extractError(e),
      );
    }
  }

  // Fallback used when /admin/dashboard/stats is unavailable.
  // Counts are limited to the first page of each list endpoint (max 100).
  Future<AdminStats> _aggregateStats() async {
    debugPrint('⚠️ AdminVM: dashboard/stats unavailable — falling back to aggregate counts');
    final results = await Future.wait([
      ApiService.getPatients().catchError((_) => <dynamic>[]),
      ApiService.getDoctors().catchError((_) => <dynamic>[]),
      ApiService.getAssistants().catchError((_) => <dynamic>[]),
      ApiService.getAdmins().catchError((_) => <dynamic>[]),
    ]);

    final patients = results[0];
    final doctors = results[1];
    final assistants = results[2];
    final admins = results[3];

    final allUsers = [
      ...doctors.cast<Map<String, dynamic>>(),
      ...assistants.cast<Map<String, dynamic>>(),
      ...admins.cast<Map<String, dynamic>>(),
    ];
    final active = allUsers.where((u) => u['is_active'] as bool? ?? true).length;

    return AdminStats(
      totalPatients: patients.length,
      totalDoctors: doctors.length,
      totalAssistants: assistants.length,
      totalAdmins: admins.length,
      activeUsers: active,
      inactiveUsers: allUsers.length - active,
    );
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> loadUsers() async {
    state = state.copyWith(isLoadingUsers: true, clearUsersError: true);
    try {
      final results = await Future.wait([
        ApiService.getDoctors().catchError((_) => <dynamic>[]),
        ApiService.getAssistants().catchError((_) => <dynamic>[]),
        ApiService.getAdmins().catchError((_) => <dynamic>[]),
      ]);

      state = state.copyWith(
        isLoadingUsers: false,
        doctors: _mapUsers(results[0], 'doctor'),
        assistants: _mapUsers(results[1], 'assistant'),
        admins: _mapUsers(results[2], 'admin'),
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingUsers: false,
        usersError: ApiService.extractError(e),
      );
    }
  }

  List<AdminUser> _mapUsers(List<dynamic> raw, String defaultRole) {
    return raw.map((m) {
      final map = m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map);
      return AdminUser.fromMap(map, defaultRole);
    }).toList();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setRoleFilter(String? role) {
    if (role == null || role.isEmpty) {
      state = state.copyWith(clearRoleFilter: true);
    } else {
      state = state.copyWith(roleFilter: role);
    }
  }

  void setStatusFilter(String? status) {
    if (status == null || status.isEmpty) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> toggleUserStatus(AdminUser user) async {
    try {
      await ApiService.updateUserStatus(user.statusUpdateId, !user.isActive);
      await loadUsers();
      return null;
    } catch (e) {
      return ApiService.extractError(e);
    }
  }

  Future<String?> deletePatient(int patientId) async {
    try {
      await ApiService.deletePatient(patientId);
      return null;
    } catch (e) {
      return ApiService.extractError(e);
    }
  }

  // ── Audit Logs ─────────────────────────────────────────────────────────────

  Future<void> loadAuditLogs({bool refresh = false}) async {
    if (state.isLoadingLogs) return;
    if (!refresh && !state.logsHasMore) return;

    final page = refresh ? 0 : state.logsPage;
    final skip = page * _pageSize;

    state = state.copyWith(isLoadingLogs: true, clearLogsError: true);
    if (refresh) {
      state = state.copyWith(auditLogs: [], logsPage: 0, logsHasMore: true);
    }

    try {
      final raw = await ApiService.getAuditLogs(
        skip: skip,
        limit: _pageSize,
        action: state.logsActionFilter,
        dateFrom: state.logsStartDate,
        dateTo: state.logsEndDate,
      );

      if (raw.isNotEmpty) {
        debugPrint('🔍 audit-log sample fields: ${raw.first.keys.toList()}');
        debugPrint('🔍 audit-log sample entry: ${raw.first}');
      }

      final newLogs = raw.map((m) {
        final map = m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map);
        return AuditLog.fromMap(map);
      }).toList();

      final combined = refresh
          ? newLogs
          : [...state.auditLogs, ...newLogs];

      state = state.copyWith(
        isLoadingLogs: false,
        auditLogs: combined,
        logsHasMore: newLogs.length >= _pageSize,
        logsPage: page + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingLogs: false,
        logsError: ApiService.extractError(e),
      );
    }
  }

  void setLogsActionFilter(String? action) {
    if (action == null || action.isEmpty) {
      state = state.copyWith(clearLogsActionFilter: true, logsPage: 0, logsHasMore: true);
    } else {
      state = state.copyWith(logsActionFilter: action, logsPage: 0, logsHasMore: true);
    }
    loadAuditLogs(refresh: true);
  }

  void setLogsDateRange(String? start, String? end) {
    state = state.copyWith(
      logsStartDate: start,
      clearLogsStartDate: start == null,
      logsEndDate: end,
      clearLogsEndDate: end == null,
      logsPage: 0,
      logsHasMore: true,
    );
    loadAuditLogs(refresh: true);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await ApiService.logout();
  }
}
