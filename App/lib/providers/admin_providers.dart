// lib/providers/admin_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Hakim/viewmodels/admin_viewmodel.dart';

final adminViewModelProvider =
    StateNotifierProvider<AdminViewModel, AdminState>(
      (ref) => AdminViewModel(),
    );
