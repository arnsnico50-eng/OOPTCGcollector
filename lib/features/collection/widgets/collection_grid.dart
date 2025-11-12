import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/card.dart';

class CollectionGrid extends StatelessWidget {
  final List<CollectionItem> collectionItems;
  final Map<String, CardPrice?> prices;
  final bool isLoading;
  final Function(String cardId, int quantity)? onQuantityChanged;
  final Function(String cardId)? onFavoriteToggle;
  final Function(String cardId)? onCardTap;

  const CollectionGrid({
    super.key,
    required this.collectionItems,
    required this.prices,
    this.isLoading = false,
    this.onQuantityChanged,
    this.onFavoriteToggle,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: collectionItems.length,
      itemBuilder: (context, index) {
        final item = collectionItems[index];
        return CollectionCardWidget(
          collectionItem: item,
          price: prices[item.cardId],
          onTap: () => onCardTap?.call(item.cardId),
          onQuantityChanged: (quantity) => onQuantityChanged?.call(item.cardId, quantity),
          onFavoriteToggle: () => onFavoriteToggle?.call(item.cardId),
        );
      },
    );
  }
}

class CollectionCardWidget extends StatelessWidget {
  final CollectionItem collectionItem;
  final CardPrice? price;
  final VoidCallback? onTap;
  final Function(int quantity)? onQuantityChanged;
  final VoidCallback? onFavoriteToggle;

  const CollectionCardWidget({
    super.key,
    required this.collectionItem,
    this.price,
    this.onTap,
    this.onQuantityChanged,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (collectionItem.favorite)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  if (collectionItem.quantity > 1)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x${collectionItem.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collectionItem.cardId,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (price != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '€${price!.priceEur.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                              ),
                              if (price!.priceUsd != null)
                                Text(
                                  '\$${price!.priceUsd!.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: collectionItem.quantity > 1
                                  ? () => onQuantityChanged?.call(collectionItem.quantity - 1)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: collectionItem.quantity > 1
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${collectionItem.quantity}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => onQuantityChanged?.call(collectionItem.quantity + 1),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Icon(
                            collectionItem.favorite ? Icons.favorite : Icons.favorite_border,
                            color: collectionItem.favorite ? Colors.red : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}