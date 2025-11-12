import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scanner_provider.dart';

class ScanHistoryWidget extends StatelessWidget {
  final List<ScanResult> scanHistory;
  final Function(ScanResult scanResult)? onRescan;
  final Function(String cardId)? onAddToCollection;

  const ScanHistoryWidget({
    super.key,
    required this.scanHistory,
    this.onRescan,
    this.onAddToCollection,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh scan history
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scanHistory.length,
        itemBuilder: (context, index) {
          final scanResult = scanHistory[index];
          return ScanHistoryItemWidget(
            scanResult: scanResult,
            onRescan: onRescan,
            onAddToCollection: onAddToCollection,
          );
        },
      ),
    );
  }
}

class ScanHistoryItemWidget extends StatelessWidget {
  final ScanResult scanResult;
  final Function(ScanResult scanResult)? onRescan;
  final Function(String cardId)? onAddToCollection;

  const ScanHistoryItemWidget({
    super.key,
    required this.scanResult,
    this.onRescan,
    this.onAddToCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showScanDetails(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Card placeholder or image
              Container(
                width: 60,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[300],
                ),
                child: const Icon(
                  Icons.image,
                  size: 24,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              // Card information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scanResult.cardName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(scanResult.confidence).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(scanResult.confidence * 100).toInt()}%',
                            style: TextStyle(
                              color: _getConfidenceColor(scanResult.confidence),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scanResult.cardId,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(scanResult.scanTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                    if (scanResult.addedToCollection) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'In Collection',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Action buttons
              Column(
                children: [
                  if (!scanResult.addedToCollection && onAddToCollection != null)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => onAddToCollection!(scanResult.cardId),
                      tooltip: 'Add to Collection',
                    ),
                  if (onRescan != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => onRescan!(scanResult),
                      tooltip: 'Rescan',
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'details':
                          _showScanDetails(context);
                          break;
                        case 'delete':
                          _deleteFromHistory(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text('Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(scanResult.cardName),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Card ID', scanResult.cardId),
            _buildDetailRow('Confidence', '${(scanResult.confidence * 100).toInt()}%'),
            _buildDetailRow('Scan Time', _formatDateTime(scanResult.scanTime)),
            _buildDetailRow('Status', scanResult.addedToCollection ? 'In Collection' : 'Not in Collection'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!scanResult.addedToCollection && onAddToCollection != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onAddToCollection!(scanResult.cardId);
              },
              child: const Text('Add to Collection'),
            ),
          if (onRescan != null)
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onRescan!(scanResult);
              },
              child: const Text('Rescan'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _deleteFromHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete from History'),
        content: const Text('Are you sure you want to delete this scan from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete from history
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}