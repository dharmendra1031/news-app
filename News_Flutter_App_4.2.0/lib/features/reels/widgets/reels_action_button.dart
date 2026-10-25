import 'package:flutter/material.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_text_label.dart';

class ReelsActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? count;
  final bool isActive;
  final VoidCallback onTap;

  const ReelsActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.count,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? primaryColor : secondaryColor,
            size: 28,
          ),
          if (count != null && count!.isNotEmpty && count != '0') ...[
            const SizedBox(height: 4),
            Text(
              count!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (label != null) ...[
            const SizedBox(height: 4),
            CustomTextLabel(
              text: label!,
              textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
