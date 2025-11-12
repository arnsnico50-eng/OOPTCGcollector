import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/card_list.dart';
import '../widgets/search_filters.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Cards'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: custom.SearchBar(
              controller: _searchController,
              onSearch: (query) {
                ref.read(searchProvider.notifier).searchCards(query);
              },
              onClear: () {
                _searchController.clear();
                ref.read(searchProvider.notifier).clearSearch();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (searchState.showFilters) const SearchFilters(),
          Expanded(
            child: _buildBody(searchState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(searchProvider.notifier).toggleFilters();
        },
        child: Icon(searchState.showFilters ? Icons.filter_list_off : Icons.filter_list),
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.isLoading && state.searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).errorColor),
            const SizedBox(height: 16),
            Text(
              'Search failed',
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
                ref.read(searchProvider.notifier).retryLastSearch();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.searchQuery.isEmpty && state.recentSearches.isNotEmpty) {
      return _buildRecentSearches();
    }

    if (state.searchResults.isEmpty && state.searchQuery.isNotEmpty) {
      return _buildEmptyState();
    }

    return CardList(
      cards: state.searchResults,
      isLoading: state.isLoading,
      onLoadMore: state.hasMoreResults
          ? () => ref.read(searchProvider.notifier).loadMoreResults()
          : null,
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: ref.read(searchProvider).recentSearches.length,
              itemBuilder: (context, index) {
                final search = ref.read(searchProvider).recentSearches[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(search.searchTerm),
                  subtitle: Text('${search.resultCount} results'),
                  onTap: () {
                    _searchController.text = search.searchTerm;
                    ref.read(searchProvider.notifier).searchCards(search.searchTerm);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      ref.read(searchProvider.notifier).removeRecentSearch(search);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No cards found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords or check your spelling',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}