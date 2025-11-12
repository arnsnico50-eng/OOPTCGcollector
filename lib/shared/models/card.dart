import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card.g.dart';

@JsonSerializable()
class Card {
  final String id;
  final String name;
  final String? setCode;
  final String? rarity;
  final int? cost;
  final int? power;
  final int? counter;
  final String? color;
  final String? type;
  final String? feature;
  final String? cardText;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? artist;
  final String? releaseDate;

  Card({
    required this.id,
    required this.name,
    this.setCode,
    this.rarity,
    this.cost,
    this.power,
    this.counter,
    this.color,
    this.type,
    this.feature,
    this.cardText,
    this.imageUrl,
    this.thumbnailUrl,
    this.artist,
    this.releaseDate,
  });

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);
  Map<String, dynamic> toJson() => _$CardToJson(this);

  Card copyWith({
    String? id,
    String? name,
    String? setCode,
    String? rarity,
    int? cost,
    int? power,
    int? counter,
    String? color,
    String? type,
    String? feature,
    String? cardText,
    String? imageUrl,
    String? thumbnailUrl,
    String? artist,
    String? releaseDate,
  }) {
    return Card(
      id: id ?? this.id,
      name: name ?? this.name,
      setCode: setCode ?? this.setCode,
      rarity: rarity ?? this.rarity,
      cost: cost ?? this.cost,
      power: power ?? this.power,
      counter: counter ?? this.counter,
      color: color ?? this.color,
      type: type ?? this.type,
      feature: feature ?? this.feature,
      cardText: cardText ?? this.cardText,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      artist: artist ?? this.artist,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Card && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Card{id: $id, name: $name, setCode: $setCode, rarity: $rarity}';
  }
}

@JsonSerializable()
class CardPrice {
  final String cardId;
  final double priceEur;
  final double? priceUsd;
  final DateTime dateRecorded;
  final String source;

  CardPrice({
    required this.cardId,
    required this.priceEur,
    this.priceUsd,
    required this.dateRecorded,
    required this.source,
  });

  factory CardPrice.fromJson(Map<String, dynamic> json) => _$CardPriceFromJson(json);
  Map<String, dynamic> toJson() => _$CardPriceToJson(this);
}

enum CardRarity {
  c('C', 'Common'),
  u('U', 'Uncommon'),
  r('R', 'Rare'),
  sr('SR', 'Super Rare'),
  sec('SEC', 'Secret Rare'),
  l('L', 'Leader'),
  sp('SP', 'Special');

  const CardRarity(this.code, this.displayName);
  final String code;
  final String displayName;

  static CardRarity? fromCode(String? code) {
    for (var rarity in CardRarity.values) {
      if (rarity.code == code?.toUpperCase()) {
        return rarity;
      }
    }
    return null;
  }
}

enum CardColor {
  red('Red', Colors.red),
  blue('Blue', Colors.blue),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  purple('Purple', Colors.purple),
  black('Black', Colors.black),
  colorless('Colorless', Colors.grey);

  const CardColor(this.displayName, this.color);
  final String displayName;
  final Color color;

  static CardColor? fromString(String? color) {
    for (var cardColor in CardColor.values) {
      if (cardColor.displayName.toLowerCase() == color?.toLowerCase()) {
        return cardColor;
      }
    }
    return null;
  }
}

enum CardType {
  leader('Leader'),
  character('Character'),
  event('Event'),
  stage('Stage');

  const CardType(this.displayName);
  final String displayName;

  static CardType? fromString(String? type) {
    for (var cardType in CardType.values) {
      if (cardType.displayName.toLowerCase() == type?.toLowerCase()) {
        return cardType;
      }
    }
    return null;
  }
}