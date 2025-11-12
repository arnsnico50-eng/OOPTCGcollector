import 'package:flutter/material.dart';

class EmptyCollection extends StatelessWidget {
  const EmptyCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Your collection is empty',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start building your One Piece TCG collection!\nSearch for cards and add them to your collection.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            icon: const Icon(Icons.search),
            label: const Text('Search Cards'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to scanner
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan a Card'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}