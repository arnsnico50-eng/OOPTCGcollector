import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final String? hintText;
  final bool autoFocus;

  const SearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search by card name or ID (e.g., OP10-032)',
    this.autoFocus = true,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      widget.onSearch(value.trim());
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onSubmitted: _onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {});
                    widget.onClear?.call();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}