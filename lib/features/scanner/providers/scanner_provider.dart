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
      // For now, simulate scanning process
      // In a real implementation, this would use camera input
      await Future.delayed(const Duration(seconds: 2));

      // Mock scan result for demonstration - this would be replaced with real text extraction
      final mockExtractedText = 'OP01-001';
      final result = await _processExtractedText(mockExtractedText);

      state = state.copyWith(
        isScanning: false,
        scanResult: result,
      );

      // Add to scan history
      await _addToScanHistory(result);

    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Scanning failed: ${e.toString()}',
      );
    }
  }

  Future<void> processImage(CameraImage cameraImage) async {
    state = state.copyWith(
      isScanning: true,
      error: null,
      scanResult: null,
    );

    try {
      final inputImage = _inputImageFromCameraImage(cameraImage);
      if (inputImage == null) {
        state = state.copyWith(
          isScanning: false,
          error: 'Failed to process image',
        );
        return;
      }

      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedText = recognizedText.text;

      if (extractedText.isEmpty) {
        state = state.copyWith(
          isScanning: false,
          error: 'No text detected in image',
        );
        return;
      }

      final result = await _processExtractedText(extractedText);

      state = state.copyWith(
        isScanning: false,
        scanResult: result,
      );

      // Add to scan history
      await _addToScanHistory(result);

    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Text extraction failed: ${e.toString()}',
      );
    }
  }

  Future<ScanResult> _processExtractedText(String extractedText) async {
    // Try to find card ID pattern first
    final cardIdPattern = RegExp(r'OP\d{2}-\d{3}', caseSensitive: false);
    final match = cardIdPattern.firstMatch(extractedText);

    if (match != null) {
      final cardId = match.group(0)!.toUpperCase();
      return await _createScanResultFromCardId(cardId, 0.95);
    }

    // If no card ID found, try to search by card name
    final cleanText = extractedText.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (cleanText.length > 2) {
      try {
        final cards = await _cardApiService.searchCards(cleanText, limit: 1);
        if (cards.isNotEmpty) {
          return _createScanResultFromCard(cards.first, 0.85);
        }
      } catch (e) {
        // Search failed, continue with fallback
      }
    }

    // Fallback: create a scan result with the extracted text
    return ScanResult(
      cardId: 'UNKNOWN',
      cardName: cleanText.isNotEmpty ? cleanText : 'Unknown Card',
      confidence: 0.3,
      imageUrl: null,
      scanTime: DateTime.now(),
    );
  }

  Future<ScanResult> _createScanResultFromCardId(String cardId, double confidence) async {
    try {
      final card = await _cardApiService.getCardById(cardId);
      if (card != null) {
        return _createScanResultFromCard(card, confidence);
      }
    } catch (e) {
      // Card not found in API
    }

    return ScanResult(
      cardId: cardId,
      cardName: 'Card Not Found',
      confidence: confidence,
      imageUrl: null,
      scanTime: DateTime.now(),
    );
  }

  ScanResult _createScanResultFromCard(Card card, double confidence) {
    return ScanResult(
      cardId: card.id,
      cardName: card.name,
      confidence: confidence,
      imageUrl: card.imageUrl,
      scanTime: DateTime.now(),
      card: card,
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage cameraImage) {
    // This is a simplified implementation
    // In a real app, you'd need to properly convert CameraImage to InputImage
    // considering the format, rotation, and plane data
    try {
      final inputImageData = InputImageData(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        imageRotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytes: cameraImage.planes[0].bytes,
      );

      return InputImage.fromBytes(bytes: cameraImage.planes[0].bytes, inputImageData: inputImageData);
    } catch (e) {
      return null;
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

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
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