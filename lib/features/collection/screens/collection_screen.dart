import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/collection_provider.dart';
import '../widgets/collection_stats.dart';
import '../widgets/collection_grid.dart';
import '../widgets/empty_collection.dart';
import '../../../app/constants/app_constants.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collectionProvider.notifier).loadCollection();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Cards'),
            Tab(text: 'Favorites'),
            Tab(text: 'Statistics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'sort_name':
                  ref.read(collectionProvider.notifier).sortBy(SortOption.name);
                  break;
                case 'sort_date':
                  ref.read(collectionProvider.notifier).sortBy(SortOption.dateAdded);
                  break;
                case 'sort_quantity':
                  ref.read(collectionProvider.notifier).sortBy(SortOption.quantity);
                  break;
                case 'sort_value':
                  ref.read(collectionProvider.notifier).sortBy(SortOption.value);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_date',
                child: Row(
                  children: [
                    Icon(Icons.date_range),
                    SizedBox(width: 8),
                    Text('Sort by Date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_quantity',
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered),
                    SizedBox(width: 8),
                    Text('Sort by Quantity'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort_value',
                child: Row(
                  children: [
                    Icon(Icons.euro),
                    SizedBox(width: 8),
                    Text('Sort by Value'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllCardsTab(collectionState),
          _buildFavoritesTab(collectionState),
          _buildStatisticsTab(collectionState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/search');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAllCardsTab(CollectionState state) {
    if (state.isLoading && state.collection.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.collection.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).errorColor),
            const SizedBox(height: 16),
            Text(
              'Failed to load collection',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(collectionProvider.notifier).loadCollection();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.collection.isEmpty) {
      return const EmptyCollection();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(collectionProvider.notifier).refreshCollection();
      },
      child: CollectionGrid(
        collectionItems: state.collection,
        prices: state.prices,
        isLoading: state.isLoading,
        onQuantityChanged: (cardId, quantity) {
          ref.read(collectionProvider.notifier).updateQuantity(cardId, quantity);
        },
        onFavoriteToggle: (cardId) {
          ref.read(collectionProvider.notifier).toggleFavorite(cardId);
        },
        onCardTap: (cardId) {
          context.pushNamed(
            AppConstants.cardDetailRouteName,
            pathParameters: {'cardId': cardId},
          );
        },
      ),
    );
  }

  Widget _buildFavoritesTab(CollectionState state) {
    if (state.favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No favorite cards yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the heart icon on cards to add them to favorites',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return CollectionGrid(
      collectionItems: state.favorites,
      prices: state.prices,
      isLoading: state.isLoading,
      onQuantityChanged: (cardId, quantity) {
        ref.read(collectionProvider.notifier).updateQuantity(cardId, quantity);
      },
      onFavoriteToggle: (cardId) {
        ref.read(collectionProvider.notifier).toggleFavorite(cardId);
      },
      onCardTap: (cardId) {
        context.pushNamed(
          AppConstants.cardDetailRouteName,
          pathParameters: {'cardId': cardId},
        );
      },
    );
  }

  Widget _buildStatisticsTab(CollectionState state) {
    return CollectionStats(
      totalCards: state.totalCards,
      uniqueCards: state.uniqueCards,
      totalValue: state.totalValue,
      rarityBreakdown: state.rarityBreakdown,
      setBreakdown: state.setBreakdown,
      colorBreakdown: state.colorBreakdown,
      isLoading: state.isLoading,
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Collection'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Search by card name...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}