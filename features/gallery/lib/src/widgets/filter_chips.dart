import 'package:flutter/material.dart';
import 'category_filter_row.dart';
import 'main_filter_row.dart';

/// Filter chips for switching gallery filters and categories.
class FilterChips extends StatelessWidget {
  /// Creates [FilterChips].
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MainFilterRow(),
        SizedBox(height: 8),
        CategoryFilterRow(),
      ],
    );
  }
}
