import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/card_api_service.dart';
import '../../../data/api/pricing_api_service.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../shared/models/card.dart';
import '../../../shared/models/collection.dart';

class CardDetailData {
  final Card card;
  final CardPrice? currentPrice;
  final CollectionItem? collectionInfo;

  CardDetailData({
    required this.card,
    this.currentPrice,
    this.collectionInfo,
  });

  CardDetailData copyWith({
    Card? card,
    CardPrice? currentPrice,
    CollectionItem? collectionInfo,
  }) {
    return CardDetailData(
      card: card ?? this.card,
      currentPrice: currentPrice ?? this.currentPrice,
      collectionInfo: collectionInfo ?? this.collectionInfo,
    );
  }
}

class CardDetailNotifier extends StateNotifier<AsyncValue<CardDetailData>> {
  final String cardId;
  final CardApiService _cardApiService;
  final PricingApiService _pricingApiService;
  final CardRepository _cardRepository;

  CardDetailNotifier(
    this.cardId,
    this._cardApiService,
    this._pricingApiService,
    this._cardRepository,
  ) : super(const AsyncValue.loading());

  Future<void> loadCardDetails() async {
    state = const AsyncValue.loading();

    try {
      final card = await _cardApiService.getCardById(cardId);
      if (card == null) {
        state = AsyncValue.error('Card not found', StackTrace.current);
        return;
      }

      final currentPrice = await _pricingApiService.getCurrentPrice(cardId);
      final collectionInfo = await _cardRepository.getCollectionItem(cardId);

      state = AsyncValue.data(CardDetailData(
        card: card,
        currentPrice: currentPrice,
        collectionInfo: collectionInfo,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is! AsyncValue<CardDetailData>) return;

    try {
      final currentCollectionInfo = currentState.value!.collectionInfo;
      final isFavorite = currentCollectionInfo?.favorite ?? false;

      if (currentCollectionInfo != null) {
        final updatedCollectionInfo = currentCollectionInfo.copyWith(
          favorite: !isFavorite,
          lastUpdated: DateTime.now(),
        );

        await _cardRepository.updateCollectionItem(updatedCollectionInfo);

        state = AsyncValue.data(currentState.value!.copyWith(
          collectionInfo: updatedCollectionInfo,
        ));
      } else {
        final newCollectionItem = CollectionItem(
          cardId: cardId,
          quantity: 0,
          dateAdded: DateTime.now(),
          lastUpdated: DateTime.now(),
          favorite: !isFavorite,
        );

        await _cardRepository.addToCollection(newCollectionItem);

        state = AsyncValue.data(currentState.value!.copyWith(
          collectionInfo: newCollectionItem,
        ));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addToCollection({
    required int quantity,
    CardCondition? condition,
    String? notes,
  }) async {
    final currentState = state;
    if (currentState is! AsyncValue<CardDetailData>) return;

    try {
      final currentCollectionInfo = currentState.value!.collectionInfo;

      if (currentCollectionInfo != null) {
        final updatedQuantity = currentCollectionInfo.quantity + quantity;
        final updatedCollectionInfo = currentCollectionInfo.copyWith(
          quantity: updatedQuantity,
          condition: condition ?? currentCollectionInfo.condition,
          notes: notes ?? currentCollectionInfo.notes,
          lastUpdated: DateTime.now(),
        );

        await _cardRepository.updateCollectionItem(updatedCollectionInfo);

        state = AsyncValue.data(currentState.value!.copyWith(
          collectionInfo: updatedCollectionInfo,
        ));
      } else {
        final newCollectionItem = CollectionItem(
          cardId: cardId,
          quantity: quantity,
          dateAdded: DateTime.now(),
          lastUpdated: DateTime.now(),
          condition: condition,
          notes: notes,
        );

        await _cardRepository.addToCollection(newCollectionItem);

        state = AsyncValue.data(currentState.value!.copyWith(
          collectionInfo: newCollectionItem,
        ));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCollectionItem({
    required int quantity,
    CardCondition? condition,
    String? notes,
  }) async {
    final currentState = state;
    if (currentState is! AsyncValue<CardDetailData>) return;

    try {
      final currentCollectionInfo = currentState.value!.collectionInfo;
      if (currentCollectionInfo == null) {
        await addToCollection(quantity: quantity, condition: condition, notes: notes);
        return;
      }

      final updatedCollectionInfo = currentCollectionInfo.copyWith(
        quantity: quantity,
        condition: condition,
        notes: notes,
        lastUpdated: DateTime.now(),
      );

      await _cardRepository.updateCollectionItem(updatedCollectionInfo);

      state = AsyncValue.data(currentState.value!.copyWith(
        collectionInfo: updatedCollectionInfo,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeFromCollection() async {
    final currentState = state;
    if (currentState is! AsyncValue<CardDetailData>) return;

    try {
      final currentCollectionInfo = currentState.value!.collectionInfo;
      if (currentCollectionInfo != null) {
        await _cardRepository.removeFromCollection(cardId);

        state = AsyncValue.data(currentState.value!.copyWith(
          collectionInfo: null,
        ));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshPrice() async {
    final currentState = state;
    if (currentState is! AsyncValue<CardDetailData>) return;

    try {
      final refreshedPrice = await _pricingApiService.getCurrentPrice(cardId);

      state = AsyncValue.data(currentState.value!.copyWith(
        currentPrice: refreshedPrice,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final cardDetailProvider = StateNotifierProvider.family<CardDetailNotifier, AsyncValue<CardDetailData>, String>(
  (ref, cardId) {
    final cardApiService = ref.watch(cardApiServiceProvider);
    final pricingApiService = ref.watch(pricingApiServiceProvider);
    final cardRepository = ref.watch(cardRepositoryProvider);

    return CardDetailNotifier(
      cardId,
      cardApiService,
      pricingApiService,
      cardRepository,
    );
  },
);

final cardApiServiceProvider = Provider<CardApiService>((ref) {
  return CardApiService();
});

final pricingApiServiceProvider = Provider<PricingApiService>((ref) {
  return PricingApiService();
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository();
});