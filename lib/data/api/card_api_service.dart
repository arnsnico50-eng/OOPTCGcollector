import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../../app/constants/app_constants.dart';
import '../../shared/models/card.dart';

final cardApiServiceProvider = Provider<CardApiService>((ref) {
  return CardApiService();
});

class CardApiService {
  late final Dio _dio;

  CardApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.optcgApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => print(object),
    ));
  }

  Future<List<Card>> getAllCards() async {
    try {
      final response = await _dio.get('/v1/cards');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['cards'] ?? response.data;
        return data.map((json) => _mapToCard(json)).toList();
      }
      throw Exception('Failed to fetch cards: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<Card>> getCardsBySet(String setCode) async {
    try {
      final response = await _dio.get('/v1/cards', queryParameters: {
        'set': setCode,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['cards'] ?? response.data;
        return data.map((json) => _mapToCard(json)).toList();
      }
      throw Exception('Failed to fetch set cards: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Card?> getCardById(String cardId) async {
    try {
      final response = await _dio.get('/v1/cards/$cardId');

      if (response.statusCode == 200) {
        return _mapToCard(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<Card>> searchCards(String query) async {
    try {
      final response = await _dio.get('/v1/cards', queryParameters: {
        'name': query,
        'limit': 50,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['cards'] ?? response.data;
        return data.map((json) => _mapToCard(json)).toList();
      }
      throw Exception('Failed to search cards: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<String>> getAvailableSets() async {
    try {
      final response = await _dio.get('/v1/sets');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['sets'] ?? response.data;
        return data.map((set) => set['code']?.toString() ?? '').toList();
      }
      throw Exception('Failed to fetch sets: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<List<Card>> getCardsByPage(int page, {int limit = 100}) async {
    try {
      final response = await _dio.get('/v1/cards', queryParameters: {
        'page': page,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['cards'] ?? response.data;
        return data.map((json) => _mapToCard(json)).toList();
      }
      throw Exception('Failed to fetch cards page: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Card _mapToCard(Map<String, dynamic> json) {
    return Card(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      setCode: json['set']?['code']?.toString(),
      rarity: json['rarity']?.toString(),
      cost: json['cost'] as int?,
      power: json['power'] as int?,
      counter: json['counter'] as int?,
      color: json['color']?.toString(),
      type: json['type']?.toString(),
      feature: json['feature']?.toString(),
      cardText: json['text']?.toString(),
      imageUrl: json['image']?.toString(),
      thumbnailUrl: json['thumbnail']?.toString(),
      artist: json['artist']?.toString(),
      releaseDate: json['releaseDate']?.toString(),
    );
  }

  // Alternative data source method using LimitlessTCG API
  Future<List<Card>> searchCardsAlternative(String query) async {
    try {
      // This is a fallback implementation for alternative APIs
      // You can implement LimitlessTCG or other sources here
      throw UnimplementedError('Alternative API search not implemented yet');
    } catch (e) {
      throw Exception('Alternative search failed: $e');
    }
  }

  Future<bool> syncCardsWithDatabase() async {
    try {
      // Fetch all cards in batches
      int page = 1;
      int totalSynced = 0;
      final batchSize = 100;

      while (true) {
        final cards = await getCardsByPage(page, limit: batchSize);

        if (cards.isEmpty) break;

        // Here you would add database insertion logic
        // This method would interact with the database service

        totalSynced += cards.length;
        page++;

        // Add delay to respect rate limits
        if (page % 10 == 0) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      return totalSynced > 0;
    } catch (e) {
      throw Exception('Card sync failed: $e');
    }
  }

  void dispose() {
    _dio.close();
  }
}