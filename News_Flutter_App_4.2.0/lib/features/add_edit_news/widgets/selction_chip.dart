import 'package:flutter/material.dart';

class SelectionChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  const SelectionChip({
    super.key,
    required this.title,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? Theme.of(context).primaryColor
              : colorScheme.primaryContainer.withOpacity(.08),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected
                    ? colorScheme.secondary
                    : colorScheme.primaryContainer,
              ),
        ),
      ),
    );
  }
}
