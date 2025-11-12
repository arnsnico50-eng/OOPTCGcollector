class AppConstants {
  // Routes
  static const String searchRoute = '/search';
  static const String searchRouteName = 'search';
  static const String collectionRoute = '/collection';
  static const String collectionRouteName = 'collection';
  static const String scannerRoute = '/scanner';
  static const String scannerRouteName = 'scanner';
  static const String settingsRoute = '/settings';
  static const String settingsRouteName = 'settings';
  static const String cardDetailRoute = '/card/:cardId';
  static const String cardDetailRouteName = 'card_detail';

  // API URLs
  static const String optcgApiBaseUrl = 'https://api.optcgapi.com';
  static const String cardmarketApiBaseUrl = 'https://api.cardmarket.com';

  // Database
  static const String databaseName = 'ooptcg_collector.db';
  static const int databaseVersion = 1;

  // Card image dimensions
  static const double cardAspectRatio = 2.5 / 3.5;
  static const int thumbnailSize = 200;
  static const int fullImageSize = 600;

  // Scanning confidence threshold
  static const double scanningConfidenceThreshold = 0.75;

  // Price update intervals
  static const Duration priceUpdateInterval = Duration(hours: 24);
  static const Duration cardDataSyncInterval = Duration(days: 7);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxSearchResults = 100;

  // UI
  static const double defaultPadding = 16.0;
  static const double cardSpacing = 8.0;
  static const double borderRadius = 12.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}