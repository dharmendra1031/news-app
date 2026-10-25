import 'package:flutter/material.dart';

class SelectionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const SelectionTile({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.primaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
