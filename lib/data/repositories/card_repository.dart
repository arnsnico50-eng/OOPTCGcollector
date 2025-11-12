import 'package:riverpod/riverpod.dart';
import '../api/card_api_service.dart';
import '../api/pricing_api_service.dart';
import '../database/database_service.dart';
import '../../shared/models/card.dart';
import '../../shared/models/collection.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final apiService = ref.watch(cardApiServiceProvider);
  final pricingService = ref.watch(pricingApiServiceProvider);
  final databaseService = ref.watch(databaseServiceProvider);
  return CardRepository(
    apiService: apiService,
    pricingService: pricingService,
    databaseService: databaseService,
  );
});

class CardRepository {
  final CardApiService _apiService;
  final PricingApiService _pricingService;
  final DatabaseService _databaseService;

  CardRepository({
    required CardApiService apiService,
    required PricingApiService pricingService,
    required DatabaseService databaseService,
  }) : _apiService = apiService,
       _pricingService = pricingService,
       _databaseService = databaseService;

  // Search operations
  Future<List<Card>> searchCards(String query) async {
    try {
      // First try local database search
      final localResults = await _databaseService.searchCards(query);

      // If we have results locally, return them
      if (localResults.isNotEmpty) {
        return localResults;
      }

      // If no local results, try API
      final apiResults = await _apiService.searchCards(query);

      // Cache API results locally
      if (apiResults.isNotEmpty) {
        await _databaseService.insertCards(apiResults);
        return apiResults;
      }

      return [];
    } catch (e) {
      throw Exception('Card search failed: $e');
    }
  }

  Future<Card?> getCardById(String cardId) async {
    try {
      // First try local database
      final localCard = await _databaseService.getCardById(cardId);
      if (localCard != null) {
        return localCard;
      }

      // If not found locally, try API
      final apiCard = await _apiService.getCardById(cardId);
      if (apiCard != null) {
        await _databaseService.insertCard(apiCard);
        return apiCard;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get card $cardId: $e');
    }
  }

  Future<List<Card>> getCardsBySet(String setCode) async {
    try {
      // Try local database first
      final localResults = await _databaseService.getCardsBySet(setCode);
      if (localResults.isNotEmpty) {
        return localResults;
      }

      // If no local results, try API
      final apiResults = await _apiService.getCardsBySet(setCode);
      if (apiResults.isNotEmpty) {
        await _databaseService.insertCards(apiResults);
        return apiResults;
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get cards for set $setCode: $e');
    }
  }

  Future<List<Card>> getCardsByRarity(String rarity) async {
    try {
      return await _databaseService.getCardsByRarity(rarity);
    } catch (e) {
      throw Exception('Failed to get cards for rarity $rarity: $e');
    }
  }

  // Collection operations
  Future<void> addToCollection(String cardId, {int quantity = 1}) async {
    try {
      final existingItem = await _databaseService.getCollectionItem(cardId);
      final now = DateTime.now();

      if (existingItem != null) {
        // Update existing item
        await _databaseService.updateCollectionQuantity(
          cardId,
          existingItem.quantity + quantity,
        );
      } else {
        // Add new item
        final newItem = CollectionItem(
          cardId: cardId,
          quantity: quantity,
          dateAdded: now,
          lastUpdated: now,
        );
        await _databaseService.addToCollection(newItem);
      }
    } catch (e) {
      throw Exception('Failed to add card to collection: $e');
    }
  }

  Future<void> removeFromCollection(String cardId, {int quantity = 1}) async {
    try {
      final existingItem = await _databaseService.getCollectionItem(cardId);
      if (existingItem == null) return;

      final newQuantity = existingItem.quantity - quantity;
      if (newQuantity <= 0) {
        await _databaseService.removeFromCollection(cardId);
      } else {
        await _databaseService.updateCollectionQuantity(cardId, newQuantity);
      }
    } catch (e) {
      throw Exception('Failed to remove card from collection: $e');
    }
  }

  Future<void> updateCollectionQuantity(String cardId, int quantity) async {
    try {
      if (quantity <= 0) {
        await _databaseService.removeFromCollection(cardId);
      } else {
        await _databaseService.updateCollectionQuantity(cardId, quantity);
      }
    } catch (e) {
      throw Exception('Failed to update collection quantity: $e');
    }
  }

  Future<void> toggleFavorite(String cardId) async {
    try {
      await _databaseService.toggleFavorite(cardId);
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  Future<void> updateCollectionNotes(String cardId, String notes) async {
    try {
      await _databaseService.updateCollectionNotes(cardId, notes);
    } catch (e) {
      throw Exception('Failed to update collection notes: $e');
    }
  }

  Future<List<CollectionItem>> getCollection() async {
    try {
      return await _databaseService.getCollection();
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  Future<List<CollectionItem>> getFavoriteCards() async {
    try {
      return await _databaseService.getFavoriteCards();
    } catch (e) {
      throw Exception('Failed to get favorite cards: $e');
    }
  }

  // Pricing operations
  Future<CardPrice?> getCardPrice(String cardId) async {
    try {
      // Try local database first
      final localPrice = await _databaseService.getLatestPrice(cardId);
      if (localPrice != null) {
        // Check if price is still fresh (less than 24 hours old)
        final age = DateTime.now().difference(localPrice.dateRecorded);
        if (age.inHours < 24) {
          return localPrice;
        }
      }

      // Get fresh price from API
      final apiPrice = await _pricingService.getCardPrice(cardId);
      if (apiPrice != null) {
        await _databaseService.addPriceRecord(apiPrice);
        return apiPrice;
      }

      // Return cached price if API fails
      return localPrice;
    } catch (e) {
      // Try to return cached price even on error
      try {
        return await _databaseService.getLatestPrice(cardId);
      } catch (_) {
        throw Exception('Failed to get card price: $e');
      }
    }
  }

  Future<Map<String, CardPrice?>> getBatchPrices(List<String> cardIds) async {
    final Map<String, CardPrice?> prices = {};

    for (final cardId in cardIds) {
      try {
        final price = await getCardPrice(cardId);
        prices[cardId] = price;
      } catch (e) {
        print('Failed to get price for $cardId: $e');
        prices[cardId] = null;
      }
    }

    return prices;
  }

  Future<bool> updateAllPrices() async {
    try {
      final collection = await getCollection();
      final cardIds = collection.map((item) => item.cardId).toList();

      int updated = 0;
      for (final cardId in cardIds) {
        try {
          final price = await _pricingService.getCardPrice(cardId);
          if (price != null) {
            await _databaseService.addPriceRecord(price);
            updated++;
          }

          // Respect rate limits
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('Failed to update price for $cardId: $e');
        }
      }

      return updated > 0;
    } catch (e) {
      throw Exception('Failed to update all prices: $e');
    }
  }

  // Statistics
  Future<int> getTotalCardCount() async {
    try {
      return await _databaseService.getTotalCardCount();
    } catch (e) {
      throw Exception('Failed to get total card count: $e');
    }
  }

  Future<int> getUniqueCardCount() async {
    try {
      return await _databaseService.getUniqueCardCount();
    } catch (e) {
      throw Exception('Failed to get unique card count: $e');
    }
  }

  Future<double> getCollectionValue() async {
    try {
      final collection = await getCollection();
      double totalValue = 0.0;

      for (final item in collection) {
        final price = await getCardPrice(item.cardId);
        if (price != null) {
          totalValue += price.priceEur * item.quantity;
        }
      }

      return totalValue;
    } catch (e) {
      throw Exception('Failed to calculate collection value: $e');
    }
  }

  // Data synchronization
  Future<bool> syncCardDatabase() async {
    try {
      return await _apiService.syncCardsWithDatabase();
    } catch (e) {
      throw Exception('Card database sync failed: $e');
    }
  }

  Future<List<String>> getAvailableSets() async {
    try {
      return await _apiService.getAvailableSets();
    } catch (e) {
      throw Exception('Failed to get available sets: $e');
    }
  }

  // Search history
  Future<void> addToSearchHistory(String searchTerm, SearchType searchType, int resultCount) async {
    try {
      final item = SearchHistoryItem(
        searchTerm: searchTerm,
        searchType: searchType,
        searchDate: DateTime.now(),
        resultCount: resultCount,
      );
      await _databaseService.addToSearchHistory(item);
    } catch (e) {
      print('Failed to add to search history: $e');
    }
  }

  Future<List<SearchHistoryItem>> getSearchHistory({int limit = 20}) async {
    try {
      return await _databaseService.getSearchHistory(limit: limit);
    } catch (e) {
      throw Exception('Failed to get search history: $e');
    }
  }
}