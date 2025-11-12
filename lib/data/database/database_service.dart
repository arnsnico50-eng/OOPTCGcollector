import 'package:sqflite/sqflite.dart';
import 'package:riverpod/riverpod.dart';
import 'database_schema.dart';
import '../../shared/models/card.dart';
import '../../shared/models/collection.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await DatabaseSchema.initializeDatabase();
    return _database!;
  }

  // Card operations
  Future<List<Card>> searchCards(String query) async {
    final db = await database;
    return await DatabaseSchema.searchCards(db, query);
  }

  Future<Card?> getCardById(String cardId) async {
    final db = await database;
    return await DatabaseSchema.getCardById(db, cardId);
  }

  Future<List<Card>> getCardsBySet(String setCode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.cardsTable,
      where: 'set_code = ?',
      whereArgs: [setCode],
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Card(
        id: map['id'],
        name: map['name'],
        setCode: map['set_code'],
        rarity: map['rarity'],
        cost: map['cost'],
        power: map['power'],
        counter: map['counter'],
        color: map['color'],
        type: map['type'],
        feature: map['feature'],
        cardText: map['card_text'],
        imageUrl: map['image_url'],
        thumbnailUrl: map['thumbnail_url'],
        artist: map['artist'],
        releaseDate: map['release_date'],
      );
    });
  }

  Future<List<Card>> getCardsByRarity(String rarity) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.cardsTable,
      where: 'rarity = ?',
      whereArgs: [rarity],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Card(
        id: map['id'],
        name: map['name'],
        setCode: map['set_code'],
        rarity: map['rarity'],
        cost: map['cost'],
        power: map['power'],
        counter: map['counter'],
        color: map['color'],
        type: map['type'],
        feature: map['feature'],
        cardText: map['card_text'],
        imageUrl: map['image_url'],
        thumbnailUrl: map['thumbnail_url'],
        artist: map['artist'],
        releaseDate: map['release_date'],
      );
    });
  }

  Future<void> insertCard(Card card) async {
    final db = await database;
    await DatabaseSchema.insertCard(db, card);
  }

  Future<void> insertCards(List<Card> cards) async {
    final db = await database;
    final batch = db.batch();

    for (final card in cards) {
      batch.insert(
        DatabaseSchema.cardsTable,
        {
          'id': card.id,
          'name': card.name,
          'set_code': card.setCode,
          'rarity': card.rarity,
          'cost': card.cost,
          'power': card.power,
          'counter': card.counter,
          'color': card.color,
          'type': card.type,
          'feature': card.feature,
          'card_text': card.cardText,
          'image_url': card.imageUrl,
          'thumbnail_url': card.thumbnailUrl,
          'artist': card.artist,
          'release_date': card.releaseDate,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // Collection operations
  Future<void> addToCollection(CollectionItem item) async {
    final db = await database;
    await DatabaseSchema.addToCollection(db, item);
  }

  Future<CollectionItem?> getCollectionItem(String cardId) async {
    final db = await database;
    return await DatabaseSchema.getCollectionItem(db, cardId);
  }

  Future<List<CollectionItem>> getCollection() async {
    final db = await database;
    return await DatabaseSchema.getCollection(db);
  }

  Future<void> updateCollectionQuantity(String cardId, int quantity) async {
    final db = await database;
    await db.update(
      DatabaseSchema.collectionTable,
      {
        'quantity': quantity,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
  }

  Future<void> toggleFavorite(String cardId) async {
    final db = await database;
    final item = await getCollectionItem(cardId);
    if (item != null) {
      await db.update(
        DatabaseSchema.collectionTable,
        {
          'favorite': !item.favorite ? 1 : 0,
          'last_updated': DateTime.now().toIso8601String(),
        },
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
    }
  }

  Future<void> updateCollectionNotes(String cardId, String notes) async {
    final db = await database;
    await db.update(
      DatabaseSchema.collectionTable,
      {
        'notes': notes,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
  }

  Future<void> removeFromCollection(String cardId) async {
    final db = await database;
    await db.delete(
      DatabaseSchema.collectionTable,
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
  }

  Future<List<CollectionItem>> getFavoriteCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.collectionTable,
      where: 'favorite = ?',
      whereArgs: [1],
      orderBy: 'date_added DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return CollectionItem(
        cardId: map['card_id'],
        quantity: map['quantity'],
        dateAdded: DateTime.parse(map['date_added']),
        lastUpdated: DateTime.parse(map['last_updated']),
        favorite: map['favorite'] == 1,
        notes: map['notes'],
        condition: CardCondition.fromString(map['condition']),
      );
    });
  }

  // Price history operations
  Future<void> addPriceRecord(CardPrice price) async {
    final db = await database;
    await DatabaseSchema.addPriceRecord(db, price);
  }

  Future<CardPrice?> getLatestPrice(String cardId) async {
    final db = await database;
    return await DatabaseSchema.getLatestPrice(db, cardId);
  }

  Future<List<CardPrice>> getPriceHistory(String cardId, {int limit = 30}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.priceHistoryTable,
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'date_recorded DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return CardPrice(
        cardId: map['card_id'],
        priceEur: map['price_eur'],
        priceUsd: map['price_usd'],
        dateRecorded: DateTime.parse(map['date_recorded']),
        source: map['source'],
      );
    });
  }

  // Search history operations
  Future<void> addToSearchHistory(SearchHistoryItem item) async {
    final db = await database;
    await db.insert(
      DatabaseSchema.searchHistoryTable,
      {
        'search_term': item.searchTerm,
        'search_type': item.searchType.displayName,
        'search_date': item.searchDate.toIso8601String(),
        'result_count': item.resultCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SearchHistoryItem>> getSearchHistory({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.searchHistoryTable,
      orderBy: 'search_date DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return SearchHistoryItem(
        searchTerm: map['search_term'],
        searchType: SearchType.fromString(map['search_type']) ?? SearchType.name,
        searchDate: DateTime.parse(map['search_date']),
        resultCount: map['result_count'],
      );
    });
  }

  // Statistics
  Future<int> getTotalCardCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(quantity) as total FROM ${DatabaseSchema.collectionTable}
    ''');
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getUniqueCardCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseSchema.collectionTable} WHERE quantity > 0
    ''');
    return result.first['count'] as int? ?? 0;
  }

  Future<List<Map<String, dynamic>>> getCollectionStats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        c.set_code,
        c.rarity,
        c.color,
        SUM(co.quantity) as total_quantity,
        COUNT(co.card_id) as unique_cards
      FROM ${DatabaseSchema.cardsTable} c
      LEFT JOIN ${DatabaseSchema.collectionTable} co ON c.id = co.card_id
      WHERE co.quantity > 0
      GROUP BY c.set_code, c.rarity, c.color
      ORDER BY total_quantity DESC
    ''');
    return maps;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}