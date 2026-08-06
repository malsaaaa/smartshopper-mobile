import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the active bottom navigation tab index reactively
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
