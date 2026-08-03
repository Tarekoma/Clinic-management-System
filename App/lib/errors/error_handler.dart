// lib/errors/error_handler.dart
// Centralized error classification and user-friendly message mapping.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'app_error.dart';

class ErrorHandler {
  ErrorHandler._();

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Parses any exception into a typed [AppError] with a user-friendly message.
  static AppError parse(Object e, {String? context}) {
    log(e, context: context);

    if (e is AppError) return e;

    if (e is DioException) return _fromDio(e);

    final msg = e.toString();

    if (_isNetworkMessage(msg)) {
      return AppError(
        type: AppErrorType.network,
        technical: msg,
        userMessage:
            'No internet connection. Please check your network and try again.',
      );
    }

    if (msg.contains('TimeoutException') || msg.contains('timed out')) {
      return AppError(
        type: AppErrorType.timeout,
        technical: msg,
        userMessage:
            'The request timed out. Please check your connection and try again.',
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      technical: msg,
      userMessage: 'An unexpected error occurred. Please try again.',
    );
  }

  /// Returns a user-friendly English message for any exception.
  /// Use this in ViewModels (no BuildContext available).
  static String friendlyMessage(Object e, {String? context}) =>
      parse(e, context: context).userMessage;

  /// Logs the error for debugging without exposing it to users.
  static void log(Object e, {String? context, StackTrace? stack}) {
    debugPrint('🔴 [${context ?? 'Error'}] $e');
    if (stack != null) debugPrint('   StackTrace: $stack');
  }

  // ── DioException mapping ────────────────────────────────────────────────────

  static AppError _fromDio(DioException e) {
    // Network-level errors (no HTTP response)
    if (e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && e.error is SocketException)) {
      return AppError(
        type: AppErrorType.network,
        technical: e.toString(),
        userMessage:
            'No internet connection. Please check your network and try again.',
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AppError(
        type: AppErrorType.timeout,
        technical: e.toString(),
        userMessage:
            'The request timed out. Please check your connection and try again.',
      );
    }

    final status = e.response?.statusCode;
    final detail = _extractDetail(e);

    switch (status) {
      case 400:
        return AppError(
          type: AppErrorType.validation,
          technical: detail,
          userMessage: detail.isNotEmpty
              ? detail
              : 'The request could not be processed. Please check your input.',
        );

      case 401:
        return AppError(
          type: AppErrorType.sessionExpired,
          technical: detail,
          userMessage:
              'Your session has expired. Please sign in again.',
        );

      case 403:
        return AppError(
          type: AppErrorType.forbidden,
          technical: detail,
          userMessage:
              'You don\'t have permission to perform this action.',
        );

      case 404:
        return AppError(
          type: AppErrorType.notFound,
          technical: detail,
          userMessage: 'The requested record was not found.',
        );

      case 409:
        return AppError(
          type: AppErrorType.conflict,
          technical: detail,
          userMessage: _mapConflictDetail(detail),
        );

      case 422:
        final readable = _humanizeValidationDetail(e);
        return AppError(
          type: AppErrorType.validation,
          technical: detail,
          userMessage: readable.isNotEmpty
              ? readable
              : 'Please check your input and try again.',
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return AppError(
          type: AppErrorType.serverUnavailable,
          technical: detail,
          userMessage:
              'The server is currently unavailable. Please try again later.',
        );
    }

    // Fallback: try to use the embedded readable message from the interceptor
    final msg = e.message ?? e.toString();
    if (_isNetworkMessage(msg)) {
      return AppError(
        type: AppErrorType.network,
        technical: msg,
        userMessage:
            'No internet connection. Please check your network and try again.',
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      technical: msg,
      userMessage: 'Something went wrong. Please try again.',
    );
  }

  // ── Detail extraction ───────────────────────────────────────────────────────

  static String _extractDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final raw = data['detail'];
      if (raw is String) return raw;
      if (raw is List && raw.isNotEmpty) {
        return raw.map((d) {
          final loc = (d['loc'] as List?)?.lastOrNull?.toString() ?? '';
          final msg = d['msg']?.toString() ?? '';
          return loc.isNotEmpty ? '$loc: $msg' : msg;
        }).join(', ');
      }
    }
    if (data is String) return data;
    return e.message ?? '';
  }

  /// Produces a human-readable validation message from a 422 response.
  /// Strips FastAPI's internal field paths and formats errors for display.
  static String _humanizeValidationDetail(DioException e) {
    final data = e.response?.data;
    if (data is! Map) return '';
    final raw = data['detail'];
    if (raw is String) return _cleanBackendMessage(raw);
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        if (item is! Map) return item.toString();
        final loc = item['loc'];
        final field = loc is List && loc.isNotEmpty
            ? loc.last.toString().replaceAll('_', ' ')
            : '';
        final msg = (item['msg'] ?? '').toString();
        if (field.isNotEmpty) {
          return '${_capitalize(field)}: ${_cleanValidationMsg(msg)}';
        }
        return _cleanValidationMsg(msg);
      }).join('\n');
    }
    return '';
  }

  // ── Conflict message mapping ────────────────────────────────────────────────

  static String _mapConflictDetail(String detail) {
    final d = detail.toLowerCase();
    if (d.contains('appointment') ||
        d.contains('slot') ||
        d.contains('time') ||
        d.contains('schedule')) {
      return 'This time slot is already booked. Please choose a different time.';
    }
    if (d.contains('email') || d.contains('user') || d.contains('account')) {
      return 'An account with this email already exists.';
    }
    if (d.contains('patient')) {
      return 'A patient with this information already exists.';
    }
    if (d.contains('report')) {
      return 'A report already exists for this visit. Please check the existing report.';
    }
    return 'A record with this information already exists.';
  }

  // ── Utilities ───────────────────────────────────────────────────────────────

  static bool _isNetworkMessage(String msg) =>
      msg.contains('SocketException') ||
      msg.contains('NetworkException') ||
      msg.contains('connection refused') ||
      msg.contains('Failed host lookup') ||
      msg.contains('No address associated with hostname') ||
      msg.contains('Network is unreachable');

  static String _cleanBackendMessage(String msg) {
    // Strip common backend prefixes that are confusing to users
    final cleaned = msg
        .replaceAll(RegExp(r'^Value error,?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^Error:\s*', caseSensitive: false), '');
    return cleaned.trim();
  }

  static String _cleanValidationMsg(String msg) {
    // FastAPI validation messages start with "Value error, " — strip it
    return msg
        .replaceAll(RegExp(r'^Value error,?\s*', caseSensitive: false), '')
        .trim();
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
