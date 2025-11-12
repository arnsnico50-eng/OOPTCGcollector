import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../../app/constants/app_constants.dart';
import '../../shared/models/card.dart';

final pricingApiServiceProvider = Provider<PricingApiService>((ref) {
  return PricingApiService();
});

class PricingApiService {
  late final Dio _dio;

  PricingApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.cardmarketApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // Don't log sensitive price data
      responseBody: false,
    ));
  }

  Future<CardPrice?> getCardPrice(String cardId) async {
    try {
      // Primary: Try optcgapi.com pricing
      final optcgPrice = await _getOptcgPrice(cardId);
      if (optcgPrice != null) return optcgPrice;

      // Fallback: Try Cardmarket API
      final cardmarketPrice = await _getCardmarketPrice(cardId);
      return cardmarketPrice;

    } catch (e) {
      print('Error fetching price for $cardId: $e');
      return null;
    }
  }

  Future<CardPrice?> _getOptcgPrice(String cardId) async {
    try {
      final response = await _dio.get(
        'https://api.optcgapi.com/v1/cards/$cardId/price',
        options: Options(
          baseUrl: 'https://api.optcgapi.com',
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        return CardPrice(
          cardId: cardId,
          priceEur: (data['price_eur'] as num?)?.toDouble() ?? 0.0,
          priceUsd: (data['price_usd'] as num?)?.toDouble(),
          dateRecorded: DateTime.now(),
          source: 'optcgapi',
        );
      }
      return null;
    } catch (e) {
      print('OP-TCG API pricing failed: $e');
      return null;
    }
  }

  Future<CardPrice?> _getCardmarketPrice(String cardId) async {
    try {
      // This would use Cardmarket API via RapidAPI or similar
      // For now, return mock data
      throw UnimplementedError('Cardmarket API integration requires subscription');
    } catch (e) {
      print('Cardmarket API pricing failed: $e');
      return null;
    }
  }

  Future<List<CardPrice>> getBatchPrices(List<String> cardIds) async {
    final List<CardPrice> prices = [];

    for (final cardId in cardIds) {
      try {
        final price = await getCardPrice(cardId);
        if (price != null) {
          prices.add(price);
        }

        // Respect rate limits
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Failed to get price for $cardId: $e');
      }
    }

    return prices;
  }

  Future<bool> updateAllPrices(List<String> cardIds) async {
    try {
      int successCount = 0;
      final batchSize = 50;

      for (int i = 0; i < cardIds.length; i += batchSize) {
        final batch = cardIds.skip(i).take(batchSize).toList();
        final prices = await getBatchPrices(batch);

        // Here you would save prices to database
        // This would interact with the database service

        successCount += prices.length;

        // Respect rate limits between batches
        if (i + batchSize < cardIds.length) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      return successCount > 0;
    } catch (e) {
      throw Exception('Price update failed: $e');
    }
  }

  Future<Map<String, double>> getCollectionValue(List<String> cardIds) async {
    final Map<String, double> values = {};

    for (final cardId in cardIds) {
      try {
        final price = await getCardPrice(cardId);
        if (price != null) {
          values[cardId] = price.priceEur;
        }

        // Small delay to respect rate limits
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        print('Failed to get value for $cardId: $e');
      }
    }

    return values;
  }

  // Mock pricing service for development
  Future<CardPrice?> getMockPrice(String cardId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));

    // Generate realistic-looking mock prices based on card ID
    final hash = cardId.hashCode;
    final basePrice = 1.0 + (hash.abs() % 500) / 10.0; // 1-50 EUR range

    return CardPrice(
      cardId: cardId,
      priceEur: basePrice,
      priceUsd: basePrice * 1.1, // EUR to USD conversion
      dateRecorded: DateTime.now(),
      source: 'mock',
    );
  }

  void dispose() {
    _dio.close();
  }
}