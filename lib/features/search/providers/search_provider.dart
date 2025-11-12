import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../shared/models/card.dart';
import '../../../shared/models/collection.dart';

// Provider for search functionality
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repository = ref.watch(cardRepositoryProvider);
  return SearchNotifier(repository);
});

class SearchNotifier extends StateNotifier<SearchState> {
  final CardRepository _repository;

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> searchCards(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        searchResults: [],
        isLoading: false,
        error: null,
      );
      return;
    }

    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
      error: null,
      page: 1,
      hasMoreResults: true,
    );

    try {
      final results = await _repository.searchCards(query);
      await _repository.addToSearchHistory(query, SearchType.name, results.length);

      state = state.copyWith(
        searchResults: results,
        isLoading: false,
        error: null,
        hasMoreResults: results.length >= 20, // Assuming 20 is page size
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        searchResults: [],
      );
    }
  }

  Future<void> loadMoreResults() async {
    if (state.isLoading || !state.hasMoreResults || state.searchQuery.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // For now, we'll use the same search method since we don't have pagination in the API yet
      // In a real implementation, you would use offset/limit parameters
      final newPage = state.page + 1;
      final additionalResults = await _repository.searchCards('${state.searchQuery} page:$newPage');

      if (additionalResults.isNotEmpty) {
        state = state.copyWith(
          searchResults: [...state.searchResults, ...additionalResults],
          isLoading: false,
          page: newPage,
          hasMoreResults: additionalResults.length >= 20,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          hasMoreResults: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadRecentSearches() async {
    try {
      final recentSearches = await _repository.getSearchHistory(limit: 10);
      state = state.copyWith(recentSearches: recentSearches);
    } catch (e) {
      // Silently handle error - recent searches are not critical
      print('Failed to load recent searches: $e');
    }
  }

  void removeRecentSearch(SearchHistoryItem search) {
    final updatedSearches = List<SearchHistoryItem>.from(state.recentSearches)
      ..remove(search);
    state = state.copyWith(recentSearches: updatedSearches);
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      searchResults: [],
      isLoading: false,
      error: null,
    );
  }

  void toggleFilters() {
    state = state.copyWith(showFilters: !state.showFilters);
  }

  void applyFilters(SearchFilters filters) {
    state = state.copyWith(
      currentFilters: filters,
      isLoading: true,
    );

    _applyCurrentFilters();
  }

  Future<void> _applyCurrentFilters() async {
    try {
      List<Card> results = [];

      if (state.searchQuery.isNotEmpty) {
        results = await _repository.searchCards(state.searchQuery);
      } else {
        // Load all cards and filter locally
        // This is not optimal but works for small datasets
        results = await _repository.searchCards('');
      }

      // Apply filters
      if (filters.set != null) {
        results = results.where((card) => card.setCode == filters.set).toList();
      }

      if (filters.rarity != null) {
        results = results.where((card) => card.rarity == filters.rarity).toList();
      }

      if (filters.color != null) {
        results = results.where((card) => card.color == filters.color).toList();
      }

      if (filters.type != null) {
        results = results.where((card) => card.type == filters.type).toList();
      }

      state = state.copyWith(
        searchResults: results,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        searchResults: [],
      );
    }
  }

  Future<void> retryLastSearch() async {
    if (state.searchQuery.isNotEmpty) {
      await searchCards(state.searchQuery);
    }
  }

  SearchFilters get filters => state.currentFilters;
}

// Search state
class SearchState {
  final String searchQuery;
  final List<Card> searchResults;
  final List<SearchHistoryItem> recentSearches;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMoreResults;
  final bool showFilters;
  final SearchFilters currentFilters;

  const SearchState({
    this.searchQuery = '',
    this.searchResults = const [],
    this.recentSearches = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMoreResults = true,
    this.showFilters = false,
    this.currentFilters = const SearchFilters(),
  });

  SearchState copyWith({
    String? searchQuery,
    List<Card>? searchResults,
    List<SearchHistoryItem>? recentSearches,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMoreResults,
    bool? showFilters,
    SearchFilters? currentFilters,
  }) {
    return SearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMoreResults: hasMoreResults ?? this.hasMoreResults,
      showFilters: showFilters ?? this.showFilters,
      currentFilters: currentFilters ?? this.currentFilters,
    );
  }
}

// Search filters model
class SearchFilters {
  final String? set;
  final String? rarity;
  final String? color;
  final String? type;
  final int? minCost;
  final int? maxCost;
  final int? minPower;
  final int? maxPower;

  const SearchFilters({
    this.set,
    this.rarity,
    this.color,
    this.type,
    this.minCost,
    this.maxCost,
    this.minPower,
    this.maxPower,
  });

  SearchFilters copyWith({
    String? set,
    String? rarity,
    String? color,
    String? type,
    int? minCost,
    int? maxCost,
    int? minPower,
    int? maxPower,
  }) {
    return SearchFilters(
      set: set ?? this.set,
      rarity: rarity ?? this.rarity,
      color: color ?? this.color,
      type: type ?? this.type,
      minCost: minCost ?? this.minCost,
      maxCost: maxCost ?? this.maxCost,
      minPower: minPower ?? this.minPower,
      maxPower: maxPower ?? this.maxPower,
    );
  }

  bool get hasActiveFilter =>
      set != null ||
      rarity != null ||
      color != null ||
      type != null ||
      minCost != null ||
      maxCost != null ||
      minPower != null ||
      maxPower != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilters &&
        other.set == set &&
        other.rarity == rarity &&
        other.color == color &&
        other.type == type &&
        other.minCost == minCost &&
        other.maxCost == maxCost &&
        other.minPower == minPower &&
        other.maxPower == maxPower;
  }

  @override
  int get hashCode {
    return set.hashCode ^
        rarity.hashCode ^
        color.hashCode ^
        type.hashCode ^
        minCost.hashCode ^
        maxCost.hashCode ^
        minPower.hashCode ^
        maxPower.hashCode;
  }
}