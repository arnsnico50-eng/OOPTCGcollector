import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/card.dart';
import '../models/collection.dart';

class DatabaseSchema {
  static const String cardsTable = 'cards_table';
  static const String collectionTable = 'collection_table';
  static const String priceHistoryTable = 'price_history_table';
  static const String searchHistoryTable = 'search_history_table';

  static Future<Database> initializeDatabase() async {
    final String path = join(await getDatabasesPath(), 'ooptcg_collector.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await _createCardsTable(db);
    await _createCollectionTable(db);
    await _createPriceHistoryTable(db);
    await _createSearchHistoryTable(db);
    await _createIndexes(db);
  }

  static Future<void> _createCardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $cardsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        set_code TEXT,
        rarity TEXT,
        cost INTEGER,
        power INTEGER,
        counter INTEGER,
        color TEXT,
        type TEXT,
        feature TEXT,
        card_text TEXT,
        image_url TEXT,
        thumbnail_url TEXT,
        artist TEXT,
        release_date TEXT
      )
    ''');
  }

  static Future<void> _createCollectionTable(Database db) async {
    await db.execute('''
      CREATE TABLE $collectionTable (
        card_id TEXT PRIMARY KEY,
        quantity INTEGER DEFAULT 0,
        date_added TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        favorite BOOLEAN DEFAULT false,
        notes TEXT,
        condition TEXT
      )
    ''');
  }

  static Future<void> _createPriceHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE $priceHistoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id TEXT NOT NULL,
        price_eur REAL NOT NULL,
        price_usd REAL,
        date_recorded TEXT NOT NULL,
        source TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES $cardsTable (id)
      )
    ''');
  }

  static Future<void> _createSearchHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE $searchHistoryTable (
        search_term TEXT PRIMARY KEY,
        search_type TEXT NOT NULL,
        search_date TEXT NOT NULL,
        result_count INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createIndexes(Database db) async {
    // Index for fast card name searches
    await db.execute('''
      CREATE INDEX idx_cards_name ON $cardsTable(name)
    ''');

    // Index for set filtering
    await db.execute('''
      CREATE INDEX idx_cards_set_code ON $cardsTable(set_code)
    ''');

    // Index for rarity filtering
    await db.execute('''
      CREATE INDEX idx_cards_rarity ON $cardsTable(rarity)
    ''');

    // Index for color filtering
    await db.execute('''
      CREATE INDEX idx_cards_color ON $cardsTable(color)
    ''');

    // Index for collection queries
    await db.execute('''
      CREATE INDEX idx_collection_quantity ON $collectionTable(quantity)
    ''');

    // Index for favorite cards
    await db.execute('''
      CREATE INDEX idx_collection_favorite ON $collectionTable(favorite)
    ''');

    // Composite index for price history queries
    await db.execute('''
      CREATE INDEX idx_price_history_card_date ON $priceHistoryTable(card_id, date_recorded)
    ''');

    // Index for search history date sorting
    await db.execute('''
      CREATE INDEX idx_search_history_date ON $searchHistoryTable(search_date)
    ''');
  }

  static Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades in future versions
    if (oldVersion < 2) {
      // Example: Add new columns or tables for version 2
    }
  }

  // Card operations
  static Future<void> insertCard(Database db, Card card) async {
    await db.insert(
      cardsTable,
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

  static Future<List<Card>> searchCards(Database db, String query) async {
    final List<Map<String, dynamic>> maps = await db.query(
      cardsTable,
      where: 'name LIKE ? OR id LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: 50,
    );

    return List.generate(maps.length, (i) {
      return Card(
        id: maps[i]['id'],
        name: maps[i]['name'],
        setCode: maps[i]['set_code'],
        rarity: maps[i]['rarity'],
        cost: maps[i]['cost'],
        power: maps[i]['power'],
        counter: maps[i]['counter'],
        color: maps[i]['color'],
        type: maps[i]['type'],
        feature: maps[i]['feature'],
        cardText: maps[i]['card_text'],
        imageUrl: maps[i]['image_url'],
        thumbnailUrl: maps[i]['thumbnail_url'],
        artist: maps[i]['artist'],
        releaseDate: maps[i]['release_date'],
      );
    });
  }

  static Future<Card?> getCardById(Database db, String cardId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      cardsTable,
      where: 'id = ?',
      whereArgs: [cardId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps[0];
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
  }

  // Collection operations
  static Future<void> addToCollection(Database db, CollectionItem item) async {
    await db.insert(
      collectionTable,
      {
        'card_id': item.cardId,
        'quantity': item.quantity,
        'date_added': item.dateAdded.toIso8601String(),
        'last_updated': item.lastUpdated.toIso8601String(),
        'favorite': item.favorite ? 1 : 0,
        'notes': item.notes,
        'condition': item.condition?.displayName,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<CollectionItem?> getCollectionItem(Database db, String cardId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      collectionTable,
      where: 'card_id = ?',
      whereArgs: [cardId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps[0];
    return CollectionItem(
      cardId: map['card_id'],
      quantity: map['quantity'],
      dateAdded: DateTime.parse(map['date_added']),
      lastUpdated: DateTime.parse(map['last_updated']),
      favorite: map['favorite'] == 1,
      notes: map['notes'],
      condition: CardCondition.fromString(map['condition']),
    );
  }

  static Future<List<CollectionItem>> getCollection(Database db) async {
    final List<Map<String, dynamic>> maps = await db.query(
      collectionTable,
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
  static Future<void> addPriceRecord(Database db, CardPrice price) async {
    await db.insert(
      priceHistoryTable,
      {
        'card_id': price.cardId,
        'price_eur': price.priceEur,
        'price_usd': price.priceUsd,
        'date_recorded': price.dateRecorded.toIso8601String(),
        'source': price.source,
      },
    );
  }

  static Future<CardPrice?> getLatestPrice(Database db, String cardId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      priceHistoryTable,
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'date_recorded DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps[0];
    return CardPrice(
      cardId: map['card_id'],
      priceEur: map['price_eur'],
      priceUsd: map['price_usd'],
      dateRecorded: DateTime.parse(map['date_recorded']),
      source: map['source'],
    );
  }
}