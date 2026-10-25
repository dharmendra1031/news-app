import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';

class BottomSheetOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const BottomSheetOption({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: selected
                ? Theme.of(context).primaryColor
                : scheme.primaryContainer.withValues(alpha: 0.10),
          ),
          child: CustomTextLabel(
            text: title,
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? scheme.secondary : scheme.primaryContainer,
                ),
          ),
        ),
      ),
    );
  }
}
