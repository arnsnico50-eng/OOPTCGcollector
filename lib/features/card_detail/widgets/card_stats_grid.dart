import 'package:flutter/material.dart';
import '../../../shared/models/card.dart';

class CardStatsGrid extends StatelessWidget {
  final Card card;

  const CardStatsGrid({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildBasicInfoRow(context),
              const Divider(height: 1, color: Colors.grey),
              _buildStatsRow(context),
              if (card.type != null || card.color != null) ...[
                const Divider(height: 1, color: Colors.grey),
                _buildTypeColorRow(context),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              context,
              'Card ID',
              card.id,
              Icons.tag,
            ),
          ),
          if (card.setCode != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                context,
                'Set',
                card.setCode!,
                Icons.category,
              ),
            ),
          ],
          if (card.rarity != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                context,
                'Rarity',
                card.rarity!,
                Icons.stars,
                valueColor: _getRarityColor(card.rarity!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final hasStats = card.cost != null || card.power != null || card.counter != null;

    if (!hasStats) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (card.cost != null) ...[
            Expanded(
              child: _buildStatItem(
                context,
                'Cost',
                card.cost.toString(),
                Icons.payment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (card.power != null) ...[
            Expanded(
              child: _buildStatItem(
                context,
                'Power',
                card.power.toString(),
                Icons.flash_on,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (card.counter != null) ...[
            Expanded(
              child: _buildStatItem(
                context,
                'Counter',
                card.counter.toString(),
                Icons.shield,
                Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeColorRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (card.type != null) ...[
            Expanded(
              child: _buildInfoItem(
                context,
                'Type',
                card.type!,
                Icons.style,
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (card.color != null) ...[
            Expanded(
              child: _buildInfoItem(
                context,
                'Color',
                card.color!,
                Icons.palette,
                valueColor: _getCardColor(card.color!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
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

  Color _getCardColor(String color) {
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

class CardFeatureChips extends StatelessWidget {
  final Card card;

  const CardFeatureChips({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (card.feature != null && card.feature!.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(
            card.feature!,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          side: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Features',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: chips,
        ),
      ],
    );
  }
}