import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../data/api/card_api_service.dart';
import '../../../shared/models/card.dart';

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final repository = ref.watch(cardRepositoryProvider);
  return ScannerNotifier(repository);
});

class ScannerNotifier extends StateNotifier<ScannerState> {
  final CardRepository _repository;
  final CardApiService _cardApiService;
  final TextRecognizer _textRecognizer;

  ScannerNotifier(this._repository)
      : _cardApiService = CardApiService(),
        _textRecognizer = GoogleMlKit.vision.textRecognizer(),
        super(const ScannerState());

  Future<void> startScanning() async {
    state = state.copyWith(
      isScanning: true,
      error: null,
      scanResult: null,
    );

    try {
      // Simulate scanning process
      // In a real implementation, this would use ML Kit or camera scanning
      await Future.delayed(const Duration(seconds: 2));

      // Mock scan result for demonstration
      final mockResult = ScanResult(
        cardId: 'OP01-001',
        cardName: 'Monkey D. Luffy',
        confidence: 0.95,
        imageUrl: null,
        scanTime: DateTime.now(),
      );

      state = state.copyWith(
        isScanning: false,
        scanResult: mockResult,
      );

      // Add to scan history
      await _addToScanHistory(mockResult);

    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Scanning failed: ${e.toString()}',
      );
    }
  }

  Future<void> stopScanning() async {
    state = state.copyWith(isScanning: false);
  }

  Future<void> addToCollection(String cardId) async {
    try {
      await _repository.addToCollection(cardId);

      // Update scan history to mark as added to collection
      if (state.scanResult?.cardId == cardId) {
        final updatedResult = state.scanResult!.copyWith(addedToCollection: true);
        state = state.copyWith(scanResult: updatedResult);
      }

      // Update history
      final updatedHistory = state.scanHistory.map((result) {
        if (result.cardId == cardId) {
          return result.copyWith(addedToCollection: true);
        }
        return result;
      }).toList();

      state = state.copyWith(scanHistory: updatedHistory);

    } catch (e) {
      state = state.copyWith(error: 'Failed to add card to collection: ${e.toString()}');
    }
  }

  Future<void> loadScanHistory() async {
    try {
      // For now, return empty history
      // In a real implementation, this would load from local storage
      state = state.copyWith(scanHistory: []);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load scan history: ${e.toString()}');
    }
  }

  Future<void> retryScan(ScanResult previousResult) async {
    state = state.copyWith(
      isScanning: true,
      error: null,
      scanResult: null,
    );

    try {
      // Simulate rescanning the same card
      await Future.delayed(const Duration(seconds: 1));

      // Get the actual card data from repository
      final card = await _repository.getCardById(previousResult.cardId);

      if (card != null) {
        final newResult = ScanResult(
          cardId: card.id,
          cardName: card.name,
          confidence: 0.98, // Higher confidence on retry
          imageUrl: card.imageUrl,
          scanTime: DateTime.now(),
          card: card,
        );

        state = state.copyWith(
          isScanning: false,
          scanResult: newResult,
        );

        await _addToScanHistory(newResult);
      } else {
        state = state.copyWith(
          isScanning: false,
          error: 'Card not found: ${previousResult.cardId}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Rescan failed: ${e.toString()}',
      );
    }
  }

  Future<void> _addToScanHistory(ScanResult result) async {
    final updatedHistory = [result, ...state.scanHistory];

    // Keep only the last 50 scans
    if (updatedHistory.length > 50) {
      updatedHistory.removeLast();
    }

    state = state.copyWith(scanHistory: updatedHistory);

    // In a real implementation, save to local storage
    // await _saveScanHistoryToStorage(updatedHistory);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearScanResult() {
    state = state.copyWith(scanResult: null);
  }
}

class ScannerState {
  final bool isScanning;
  final ScanResult? scanResult;
  final List<ScanResult> scanHistory;
  final String? error;

  const ScannerState({
    this.isScanning = false,
    this.scanResult,
    this.scanHistory = const [],
    this.error,
  });

  ScannerState copyWith({
    bool? isScanning,
    ScanResult? scanResult,
    List<ScanResult>? scanHistory,
    String? error,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      scanResult: scanResult ?? this.scanResult,
      scanHistory: scanHistory ?? this.scanHistory,
      error: error,
    );
  }
}

class ScanResult {
  final String cardId;
  final String cardName;
  final double confidence;
  final String? imageUrl;
  final DateTime scanTime;
  final Card? card;
  final bool addedToCollection;

  ScanResult({
    required this.cardId,
    required this.cardName,
    required this.confidence,
    this.imageUrl,
    required this.scanTime,
    this.card,
    this.addedToCollection = false,
  });

  ScanResult copyWith({
    String? cardId,
    String? cardName,
    double? confidence,
    String? imageUrl,
    DateTime? scanTime,
    Card? card,
    bool? addedToCollection,
  }) {
    return ScanResult(
      cardId: cardId ?? this.cardId,
      cardName: cardName ?? this.cardName,
      confidence: confidence ?? this.confidence,
      imageUrl: imageUrl ?? this.imageUrl,
      scanTime: scanTime ?? this.scanTime,
      card: card ?? this.card,
      addedToCollection: addedToCollection ?? this.addedToCollection,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanResult &&
        other.cardId == cardId &&
        other.scanTime == scanTime;
  }

  @override
  int get hashCode => cardId.hashCode ^ scanTime.hashCode;

  @override
  String toString() {
    return 'ScanResult{cardId: $cardId, cardName: $cardName, confidence: $confidence}';
  }
}