import 'package:json_annotation/json_annotation.dart';

import 'card.dart';

part 'collection.g.dart';

@JsonSerializable()
class CollectionItem {
  final String cardId;
  final int quantity;
  final DateTime dateAdded;
  final DateTime lastUpdated;
  final bool favorite;
  final String? notes;
  final CardCondition? condition;

  CollectionItem({
    required this.cardId,
    required this.quantity,
    required this.dateAdded,
    required this.lastUpdated,
    this.favorite = false,
    this.notes,
    this.condition,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) => _$CollectionItemFromJson(json);
  Map<String, dynamic> toJson() => _$CollectionItemToJson(this);

  CollectionItem copyWith({
    String? cardId,
    int? quantity,
    DateTime? dateAdded,
    DateTime? lastUpdated,
    bool? favorite,
    String? notes,
    CardCondition? condition,
  }) {
    return CollectionItem(
      cardId: cardId ?? this.cardId,
      quantity: quantity ?? this.quantity,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      favorite: favorite ?? this.favorite,
      notes: notes ?? this.notes,
      condition: condition ?? this.condition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionItem && other.cardId == cardId;
  }

  @override
  int get hashCode => cardId.hashCode;

  @override
  String toString() {
    return 'CollectionItem{cardId: $cardId, quantity: $quantity, favorite: $favorite}';
  }
}

@JsonSerializable()
class CollectionStats {
  final int totalCards;
  final int uniqueCards;
  final double totalValue;
  final Map<CardRarity, int> rarityBreakdown;
  final Map<CardColor, int> colorBreakdown;
  final Map<String, int> setBreakdown;

  CollectionStats({
    required this.totalCards,
    required this.uniqueCards,
    required this.totalValue,
    required this.rarityBreakdown,
    required this.colorBreakdown,
    required this.setBreakdown,
  });

  factory CollectionStats.fromJson(Map<String, dynamic> json) => _$CollectionStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CollectionStatsToJson(this);
}

enum CardCondition {
  mint('Mint'),
  nearMint('Near Mint'),
  excellent('Excellent'),
  good('Good'),
  fair('Fair'),
  poor('Poor');

  const CardCondition(this.displayName);
  final String displayName;

  static CardCondition? fromString(String? condition) {
    for (var cardCondition in CardCondition.values) {
      if (cardCondition.displayName.toLowerCase() == condition?.toLowerCase()) {
        return cardCondition;
      }
    }
    return null;
  }
}

@JsonSerializable()
class SearchHistoryItem {
  final String searchTerm;
  final SearchType searchType;
  final DateTime searchDate;
  final int resultCount;

  SearchHistoryItem({
    required this.searchTerm,
    required this.searchType,
    required this.searchDate,
    required this.resultCount,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) => _$SearchHistoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$SearchHistoryItemToJson(this);
}

enum SearchType {
  name('name'),
  id('id'),
  text('text'),
  set('set'),
  advanced('advanced');

  const SearchType(this.displayName);
  final String displayName;

  static SearchType? fromString(String? type) {
    for (var searchType in SearchType.values) {
      if (searchType.displayName.toLowerCase() == type?.toLowerCase()) {
        return searchType;
      }
    }
    return null;
  }
}