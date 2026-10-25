import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/notification_preferences/models/notification_preference_item.dart';
import 'package:news/utils/ui_utils.dart';

/// One notification-type row on the [NotificationPreferenceScreen]: title,
/// optional description, and a check indicator; tapping anywhere fires [onToggle].
class NotificationPreferenceCard extends StatelessWidget {
  final NotificationPreferenceItem item;
  final VoidCallback onToggle;

  const NotificationPreferenceCard(
      {super.key, required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
          border:
              Border.all(color: colorScheme.primaryContainer.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomTextLabel(
                    text: item.titleKey,
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            color: colorScheme.primaryContainer,
                            fontWeight: FontWeight.w600,
                            height: 24 / 16),
                  ),
                  if (item.descriptionKey != null) ...<Widget>[
                    const SizedBox(height: 4.0),
                    CustomTextLabel(
                      text: item.descriptionKey!,
                      textStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              color: colorScheme.primaryContainer,
                              fontWeight: FontWeight.w400,
                              height: 24 / 14),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4.0),
            Icon(
              item.enabled ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 24.0,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
