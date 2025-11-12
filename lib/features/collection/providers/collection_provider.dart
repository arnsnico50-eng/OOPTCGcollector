import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../shared/models/collection.dart';

enum SortOption {
  name,
  dateAdded,
  quantity,
  value,
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  final repository = ref.watch(cardRepositoryProvider);
  return CollectionNotifier(repository);
});

class CollectionNotifier extends StateNotifier<CollectionState> {
  final CardRepository _repository;

  CollectionNotifier(this._repository) : super(const CollectionState());

  Future<void> loadCollection() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final collection = await _repository.getCollection();
      final favorites = await _repository.getFavoriteCards();
      final totalCards = await _repository.getTotalCardCount();
      final uniqueCards = await _repository.getUniqueCardCount();
      final totalValue = await _repository.getCollectionValue();

      // Load prices for all collection items
      final cardIds = collection.map((item) => item.cardId).toList();
      final prices = await _repository.getBatchPrices(cardIds);

      // Calculate breakdowns
      final stats = await _repository.getCollectionStats();
      final rarityBreakdown = <String, int>{};
      final setBreakdown = <String, int>{};
      final colorBreakdown = <String, int>{};

      for (final stat in stats) {
        final rarity = stat['rarity'] as String? ?? 'Unknown';
        final set = stat['set_code'] as String? ?? 'Unknown';
        final color = stat['color'] as String? ?? 'Unknown';
        final quantity = stat['total_quantity'] as int;

        rarityBreakdown[rarity] = (rarityBreakdown[rarity] ?? 0) + quantity;
        setBreakdown[set] = (setBreakdown[set] ?? 0) + quantity;
        colorBreakdown[color] = (colorBreakdown[color] ?? 0) + quantity;
      }

      state = state.copyWith(
        collection: collection,
        favorites: favorites,
        totalCards: totalCards,
        uniqueCards: uniqueCards,
        totalValue: totalValue,
        prices: prices,
        rarityBreakdown: rarityBreakdown,
        setBreakdown: setBreakdown,
        colorBreakdown: colorBreakdown,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshCollection() async {
    await loadCollection();
  }

  Future<void> updateQuantity(String cardId, int quantity) async {
    try {
      await _repository.updateCollectionQuantity(cardId, quantity);

      // Update local state
      final updatedCollection = state.collection.map((item) {
        if (item.cardId == cardId) {
          return item.copyWith(
            quantity: quantity,
            lastUpdated: DateTime.now(),
          );
        }
        return item;
      }).toList();

      state = state.copyWith(collection: updatedCollection);

      // Recalculate totals
      await _recalculateTotals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleFavorite(String cardId) async {
    try {
      await _repository.toggleFavorite(cardId);

      // Update local state
      final updatedCollection = state.collection.map((item) {
        if (item.cardId == cardId) {
          return item.copyWith(
            favorite: !item.favorite,
            lastUpdated: DateTime.now(),
          );
        }
        return item;
      }).toList();

      final updatedFavorites = updatedCollection.where((item) => item.favorite).toList();

      state = state.copyWith(
        collection: updatedCollection,
        favorites: updatedFavorites,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addToCollection(String cardId, {int quantity = 1}) async {
    try {
      await _repository.addToCollection(cardId, quantity: quantity);
      await loadCollection(); // Reload full collection
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeFromCollection(String cardId) async {
    try {
      await _repository.removeFromCollection(cardId);

      final updatedCollection = state.collection.where((item) => item.cardId != cardId).toList();
      final updatedFavorites = updatedCollection.where((item) => item.favorite).toList();

      state = state.copyWith(
        collection: updatedCollection,
        favorites: updatedFavorites,
      );

      await _recalculateTotals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updatePrices() async {
    try {
      state = state.copyWith(isLoading: true);

      final success = await _repository.updateAllPrices();
      if (success) {
        await loadCollection();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sortBy(SortOption option) async {
    List<CollectionItem> sortedCollection;

    switch (option) {
      case SortOption.name:
        // Need to fetch card data to sort by name
        sortedCollection = List.from(state.collection);
        // This would require fetching card names from the database
        // For now, keep current order
        break;
      case SortOption.dateAdded:
        sortedCollection = List.from(state.collection)
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortOption.quantity:
        sortedCollection = List.from(state.collection)
          ..sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case SortOption.value:
        sortedCollection = List.from(state.collection)
          ..sort((a, b) {
            final priceA = state.prices[a.cardId]?.priceEur ?? 0.0;
            final priceB = state.prices[b.cardId]?.priceEur ?? 0.0;
            final valueA = priceA * a.quantity;
            final valueB = priceB * b.quantity;
            return valueB.compareTo(valueA);
          });
        break;
    }

    state = state.copyWith(collection: sortedCollection);
  }

  Future<void> _recalculateTotals() async {
    try {
      final totalCards = await _repository.getTotalCardCount();
      final uniqueCards = await _repository.getUniqueCardCount();
      final totalValue = await _repository.getCollectionValue();

      state = state.copyWith(
        totalCards: totalCards,
        uniqueCards: uniqueCards,
        totalValue: totalValue,
      );
    } catch (e) {
      // Silently handle error in recalculation
      print('Failed to recalculate totals: $e');
    }
  }

  Future<void> searchInCollection(String query) async {
    if (query.trim().isEmpty) {
      await loadCollection();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final collection = await _repository.getCollection();
      final searchResults = collection.where((item) {
        // This would need to fetch card names to search properly
        // For now, return empty results
        return false;
      }).toList();

      state = state.copyWith(
        collection: searchResults,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

class CollectionState {
  final List<CollectionItem> collection;
  final List<CollectionItem> favorites;
  final int totalCards;
  final int uniqueCards;
  final double totalValue;
  final Map<String, CardPrice?> prices;
  final Map<String, int> rarityBreakdown;
  final Map<String, int> setBreakdown;
  final Map<String, int> colorBreakdown;
  final bool isLoading;
  final String? error;

  const CollectionState({
    this.collection = const [],
    this.favorites = const [],
    this.totalCards = 0,
    this.uniqueCards = 0,
    this.totalValue = 0.0,
    this.prices = const {},
    this.rarityBreakdown = const {},
    this.setBreakdown = const {},
    this.colorBreakdown = const {},
    this.isLoading = false,
    this.error,
  });

  CollectionState copyWith({
    List<CollectionItem>? collection,
    List<CollectionItem>? favorites,
    int? totalCards,
    int? uniqueCards,
    double? totalValue,
    Map<String, CardPrice?>? prices,
    Map<String, int>? rarityBreakdown,
    Map<String, int>? setBreakdown,
    Map<String, int>? colorBreakdown,
    bool? isLoading,
    String? error,
  }) {
    return CollectionState(
      collection: collection ?? this.collection,
      favorites: favorites ?? this.favorites,
      totalCards: totalCards ?? this.totalCards,
      uniqueCards: uniqueCards ?? this.uniqueCards,
      totalValue: totalValue ?? this.totalValue,
      prices: prices ?? this.prices,
      rarityBreakdown: rarityBreakdown ?? this.rarityBreakdown,
      setBreakdown: setBreakdown ?? this.setBreakdown,
      colorBreakdown: colorBreakdown ?? this.colorBreakdown,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}