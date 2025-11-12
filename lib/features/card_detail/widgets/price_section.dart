import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/card.dart';
import '../providers/card_detail_provider.dart';

class PriceSection extends ConsumerStatefulWidget {
  final String cardId;
  final CardPrice? currentPrice;

  const PriceSection({
    super.key,
    required this.cardId,
    this.currentPrice,
  });

  @override
  ConsumerState<PriceSection> createState() => _PriceSectionState();
}

class _PriceSectionState extends ConsumerState<PriceSection> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final cardDetailState = ref.watch(cardDetailProvider(widget.cardId));
    final currentPrice = cardDetailState.whenOrNull(
      data: (data) => data.currentPrice,
    ) ?? widget.currentPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Price Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              onPressed: _isRefreshing ? null : _refreshPrice,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh Price',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (currentPrice != null)
          _buildPriceCard(context, currentPrice)
        else
          _buildNoPriceCard(context),
      ],
    );
  }

  Widget _buildPriceCard(BuildContext context, CardPrice price) {
    final currencyFormat = NumberFormat.currency(
      symbol: '€',
      decimalDigits: 2,
    );

    final usdFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Price',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      currencyFormat.format(price.priceEur),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
                if (price.priceUsd != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'USD',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        usdFormat.format(price.priceUsd!),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPriceMeta(context, price),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceMeta(BuildContext context, CardPrice price) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final formattedDate = dateFormat.format(price.dateRecorded);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Source: ${price.source} • Updated: $formattedDate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPriceCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.monetization_on_outlined,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              'No Price Data Available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Price information is currently unavailable for this card. Try refreshing later.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPrice() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await ref
          .read(cardDetailProvider(widget.cardId).notifier)
          .refreshPrice();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh price: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}

class PriceTrendIndicator extends StatelessWidget {
  final double? currentPrice;
  final double? previousPrice;
  final Duration? timePeriod;

  const PriceTrendIndicator({
    super.key,
    this.currentPrice,
    this.previousPrice,
    this.timePeriod,
  });

  @override
  Widget build(BuildContext context) {
    if (currentPrice == null || previousPrice == null) {
      return const SizedBox.shrink();
    }

    final difference = currentPrice! - previousPrice!;
    final percentageChange = (difference / previousPrice!) * 100;
    final isPositive = difference >= 0;

    Color trendColor;
    IconData trendIcon;

    if (difference == 0) {
      trendColor = Colors.grey;
      trendIcon = Icons.remove;
    } else if (isPositive) {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up;
    } else {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: trendColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendIcon,
            color: trendColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
            style: TextStyle(
              color: trendColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class PriceHistoryPreview extends StatelessWidget {
  final String cardId;

  const PriceHistoryPreview({
    super.key,
    required this.cardId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Price history chart will be available in a future update.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}