import 'package:flutter/material.dart';

class CollectionStats extends StatelessWidget {
  final int totalCards;
  final int uniqueCards;
  final double totalValue;
  final Map<String, int> rarityBreakdown;
  final Map<String, int> setBreakdown;
  final Map<String, int> colorBreakdown;
  final bool isLoading;

  const CollectionStats({
    super.key,
    required this.totalCards,
    required this.uniqueCards,
    required this.totalValue,
    required this.rarityBreakdown,
    required this.setBreakdown,
    required this.colorBreakdown,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSection(context),
          const SizedBox(height: 24),
          _buildBreakdownSection(context),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collection Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Cards',
                '$totalCards',
                Icons.collections,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Unique Cards',
                '$uniqueCards',
                Icons.star,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          context,
          'Total Value',
          '€${totalValue.toStringAsFixed(2)}',
          Icons.euro,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collection Breakdown',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (rarityBreakdown.isNotEmpty) _buildRarityBreakdown(context),
        if (setBreakdown.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSetBreakdown(context),
        ],
        if (colorBreakdown.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildColorBreakdown(context),
        ],
      ],
    );
  }

  Widget _buildRarityBreakdown(BuildContext context) {
    return _buildBreakdownCard(
      context,
      'By Rarity',
      rarityBreakdown,
      _getRarityColor,
    );
  }

  Widget _buildSetBreakdown(BuildContext context) {
    return _buildBreakdownCard(
      context,
      'By Set',
      setBreakdown,
      (key) => Theme.of(context).primaryColor,
    );
  }

  Widget _buildColorBreakdown(BuildContext context) {
    return _buildBreakdownCard(
      context,
      'By Color',
      colorBreakdown,
      _getColorValue,
    );
  }

  Widget _buildBreakdownCard(
    BuildContext context,
    String title,
    Map<String, int> data,
    Color Function(String) colorFunction,
  ) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...sortedEntries.take(5).map((entry) {
            final percentage = totalCards > 0 ? (entry.value / totalCards * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorFunction(entry.key),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${percentage.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }),
          if (sortedEntries.length > 5)
            TextButton(
              onPressed: () {
                // TODO: Show full breakdown
              },
              child: Text('Show all ${sortedEntries.length} items'),
            ),
        ],
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

  Color _getColorValue(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'black':
        return Colors.black;
      case 'colorless':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}