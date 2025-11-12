import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';

class SearchFilters extends ConsumerStatefulWidget {
  const SearchFilters({super.key});

  @override
  ConsumerState<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends ConsumerState<SearchFilters> {
  String? _selectedSet;
  String? _selectedRarity;
  String? _selectedColor;
  String? _selectedType;

  final List<String> _sets = [
    'OP01', 'OP02', 'OP03', 'OP04', 'OP05', 'OP06', 'OP07', 'OP08', 'OP09', 'OP10',
    'ST01', 'ST02', 'ST03', 'ST04', 'ST05', 'ST06',
  ];

  final List<String> _rarities = ['C', 'U', 'R', 'SR', 'SEC', 'L', 'SP'];
  final List<String> _colors = ['Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Black', 'Colorless'];
  final List<String> _types = ['Leader', 'Character', 'Event', 'Stage'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFilterDropdown<String>(
                'Set',
                _selectedSet,
                _sets,
                (value) => setState(() => _selectedSet = value),
              ),
              _buildFilterDropdown<String>(
                'Rarity',
                _selectedRarity,
                _rarities,
                (value) => setState(() => _selectedRarity = value),
              ),
              _buildFilterDropdown<String>(
                'Color',
                _selectedColor,
                _colors,
                (value) => setState(() => _selectedColor = value),
              ),
              _buildFilterDropdown<String>(
                'Type',
                _selectedType,
                _types,
                (value) => setState(() => _selectedType = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String label,
    T? value,
    List<T> items,
    Function(T?) onChanged,
  ) {
    return Container(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<T>(
                value: null,
                child: Text(
                  'All',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ...items.map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    final filters = SearchFilters(
      set: _selectedSet,
      rarity: _selectedRarity,
      color: _selectedColor,
      type: _selectedType,
    );

    ref.read(searchProvider.notifier).applyFilters(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedSet = null;
      _selectedRarity = null;
      _selectedColor = null;
      _selectedType = null;
    });

    ref.read(searchProvider.notifier).applyFilters(const SearchFilters());
  }
}