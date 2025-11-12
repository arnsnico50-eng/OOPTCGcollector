import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      state = state.copyWith(
        autoSync: prefs.getBool('auto_sync') ?? true,
        autoPriceUpdates: prefs.getBool('auto_price_updates') ?? true,
        autoCapture: prefs.getBool('auto_capture') ?? true,
        confidenceThreshold: prefs.getDouble('confidence_threshold') ?? 0.75,
        soundEffects: prefs.getBool('sound_effects') ?? true,
        darkMode: prefs.getBool('dark_mode') ?? false,
        gridView: prefs.getBool('grid_view') ?? true,
        showCardValues: prefs.getBool('show_card_values') ?? true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      switch (value.runtimeType) {
        case bool:
          await prefs.setBool(key, value);
          break;
        case double:
          await prefs.setDouble(key, value);
          break;
        case int:
          await prefs.setInt(key, value);
          break;
        case String:
          await prefs.setString(key, value);
          break;
        default:
          throw UnsupportedError('Unsupported type: ${value.runtimeType}');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to save setting: $e');
    }
  }

  Future<void> updateAutoSync(bool value) async {
    state = state.copyWith(autoSync: value);
    await _saveSetting('auto_sync', value);
  }

  Future<void> updateAutoPriceUpdates(bool value) async {
    state = state.copyWith(autoPriceUpdates: value);
    await _saveSetting('auto_price_updates', value);
  }

  Future<void> updateAutoCapture(bool value) async {
    state = state.copyWith(autoCapture: value);
    await _saveSetting('auto_capture', value);
  }

  Future<void> updateConfidenceThreshold(double value) async {
    state = state.copyWith(confidenceThreshold: value);
    await _saveSetting('confidence_threshold', value);
  }

  Future<void> updateSoundEffects(bool value) async {
    state = state.copyWith(soundEffects: value);
    await _saveSetting('sound_effects', value);
  }

  Future<void> updateDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _saveSetting('dark_mode', value);
  }

  Future<void> updateGridView(bool value) async {
    state = state.copyWith(gridView: value);
    await _saveSetting('grid_view', value);
  }

  Future<void> updateShowCardValues(bool value) async {
    state = state.copyWith(showCardValues: value);
    await _saveSetting('show_card_values', value);
  }

  Future<void> updateAllPrices() async {
    state = state.copyWith(isUpdatingPrices: true);

    try {
      // TODO: Implement price update logic
      // This would interact with the collection repository
      await Future.delayed(const Duration(seconds: 3)); // Simulate update

      state = state.copyWith(isUpdatingPrices: false);
    } catch (e) {
      state = state.copyWith(
        isUpdatingPrices: false,
        error: 'Failed to update prices: $e',
      );
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      // TODO: Also clear from database
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear search history: $e');
    }
  }

  Future<void> clearScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scan_history');
      // TODO: Also clear from database
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear scan history: $e');
    }
  }

  Future<void> exportCollection() async {
    state = state.copyWith(isExporting: true);

    try {
      // TODO: Implement export logic
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(isExporting: false);
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to export collection: $e',
      );
    }
  }

  Future<void> importCollection() async {
    state = state.copyWith(isImporting: true);

    try {
      // TODO: Implement import logic
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(isImporting: false);
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: 'Failed to import collection: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class SettingsState {
  final bool autoSync;
  final bool autoPriceUpdates;
  final bool autoCapture;
  final double confidenceThreshold;
  final bool soundEffects;
  final bool darkMode;
  final bool gridView;
  final bool showCardValues;
  final bool isLoading;
  final bool isUpdatingPrices;
  final bool isExporting;
  final bool isImporting;
  final String? error;

  const SettingsState({
    this.autoSync = true,
    this.autoPriceUpdates = true,
    this.autoCapture = true,
    this.confidenceThreshold = 0.75,
    this.soundEffects = true,
    this.darkMode = false,
    this.gridView = true,
    this.showCardValues = true,
    this.isLoading = false,
    this.isUpdatingPrices = false,
    this.isExporting = false,
    this.isImporting = false,
    this.error,
  });

  SettingsState copyWith({
    bool? autoSync,
    bool? autoPriceUpdates,
    bool? autoCapture,
    double? confidenceThreshold,
    bool? soundEffects,
    bool? darkMode,
    bool? gridView,
    bool? showCardValues,
    bool? isLoading,
    bool? isUpdatingPrices,
    bool? isExporting,
    bool? isImporting,
    String? error,
  }) {
    return SettingsState(
      autoSync: autoSync ?? this.autoSync,
      autoPriceUpdates: autoPriceUpdates ?? this.autoPriceUpdates,
      autoCapture: autoCapture ?? this.autoCapture,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      soundEffects: soundEffects ?? this.soundEffects,
      darkMode: darkMode ?? this.darkMode,
      gridView: gridView ?? this.gridView,
      showCardValues: showCardValues ?? this.showCardValues,
      isLoading: isLoading ?? this.isLoading,
      isUpdatingPrices: isUpdatingPrices ?? this.isUpdatingPrices,
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      error: error,
    );
  }
}