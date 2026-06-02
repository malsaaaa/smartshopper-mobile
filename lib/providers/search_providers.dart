import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing recent search history
final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]);

  void addSearch(String query) {
    if (query.isEmpty) return;
    
    // Remove if already exists to move to top
    final newState = List<String>.from(state)..remove(query);
    
    // Add to top and limit to 5
    state = [query, ...newState].take(5).toList();
  }

  void clear() {
    state = [];
  }
}

/// Static list of popular searches
final popularSearchesProvider = Provider<List<String>>((ref) {
  return ['Milo', 'Maggi', 'Rice', 'Teh Tarik', 'Soap'];
});
