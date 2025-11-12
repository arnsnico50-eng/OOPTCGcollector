import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/card_detail_provider.dart';
import '../widgets/interactive_card_image.dart';
import '../widgets/card_stats_grid.dart';
import '../widgets/price_section.dart';
import '../widgets/add_to_collection_button.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  final String cardId;

  const CardDetailScreen({
    super.key,
    required this.cardId,
  });

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardDetailProvider(widget.cardId).notifier).loadCardDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardDetailState = ref.watch(cardDetailProvider(widget.cardId));

    return Scaffold(
      body: cardDetailState.when(
        data: (cardData) => _buildContent(context, cardData),
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(context, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CardDetailData cardData) {
    final card = cardData.card;
    final collectionInfo = cardData.collectionInfo;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          floating: false,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                collectionInfo?.isFavorite ?? false
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: collectionInfo?.isFavorite ?? false
                    ? Colors.red
                    : null,
              ),
              onPressed: () {
                ref
                    .read(cardDetailProvider(widget.cardId).notifier)
                    .toggleFavorite();
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: InteractiveCardImage(imageUrl: card.imageUrl),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(card.id),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(width: 8),
                    if (card.setCode != null)
                      Chip(
                        label: Text(card.setCode!),
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withOpacity(0.1),
                      ),
                    const SizedBox(width: 8),
                    if (card.rarity != null)
                      Chip(
                        label: Text(card.rarity!),
                        backgroundColor: _getRarityColor(card.rarity!)
                            .withOpacity(0.2),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                CardStatsGrid(card: card),
                const SizedBox(height: 24),
                PriceSection(
                  cardId: card.id,
                  currentPrice: cardData.currentPrice,
                ),
                const SizedBox(height: 24),
                AddToCollectionButton(
                  cardId: card.id,
                  collectionInfo: collectionInfo,
                ),
                if (card.cardText != null && card.cardText!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Card Text',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.cardText!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (card.artist != null || card.releaseDate != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Additional Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (card.artist != null)
                    _buildInfoRow(context, 'Artist', card.artist!),
                  if (card.releaseDate != null)
                    _buildInfoRow(context, 'Release Date', card.releaseDate!),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load card details',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(cardDetailProvider(widget.cardId).notifier)
                      .loadCardDetails();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'C':
        return Colors.grey;
      case 'U':
        return Colors.green;
      case 'R':
        return Colors.blue;
      case 'SR':
        return Colors.purple;
      case 'SEC':
        return Colors.orange;
      case 'L':
        return Colors.red;
      case 'SP':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}