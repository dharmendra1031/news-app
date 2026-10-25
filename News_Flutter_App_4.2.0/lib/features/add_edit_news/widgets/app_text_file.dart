import 'package:flutter/material.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TapRegionCallback? onComplete;

  /// When true, the hint becomes a floating label that lifts onto the field's
  /// border outline once the field is focused or has a value.
  final bool floatingLabel;

  /// Gap above the field. 16 is the Create News form's rhythm; the Create
  /// Podcast form stacks its fields itself at 12, so it passes 0.
  final double topMargin;

  /// Shown but not editable — the Create Episode form displays the parent
  /// podcast this way. Styled exactly like a normal field, so the design is
  /// unchanged; only the caret and keyboard are suppressed.
  final bool readOnly;

  /// Defaults to text. The Create Episode form's episode number passes
  /// [TextInputType.number].
  final TextInputType? keyboardType;

  const AppTextField(
      {super.key,
      required this.controller,
      required this.hint,
      this.maxLines = 1,
      this.validator,
      this.onChanged,
      this.onComplete,
      this.floatingLabel = false,
      this.topMargin = 16,
      this.readOnly = false,
      this.keyboardType});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Figma body-medium: 14px on a 20px line box. Pinning the line height keeps
    // the field at exactly 56 (18 + 20 + 18) instead of the font's default.
    final baseStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(height: 20 / 14, letterSpacing: 0.25);

    final label = UiUtils.getTranslatedLabel(context, hint);

    if (floatingLabel) {
      final outline = OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide:
            BorderSide(color: scheme.primaryContainer.withOpacity(0.3)),
      );
      return Container(
        margin: EdgeInsets.only(top: topMargin),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: TextFormField(
          controller: controller,
          minLines: 1,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          onTapOutside: onComplete,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: baseStyle?.copyWith(color: scheme.primaryContainer),
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            labelStyle: baseStyle?.copyWith(
                color: scheme.primaryContainer.withOpacity(0.7)),
            floatingLabelStyle:
                baseStyle?.copyWith(color: Theme.of(context).primaryColor),
            border: outline,
            enabledBorder: outline,
            focusedBorder: outline.copyWith(
              borderSide: BorderSide(
                  color: Theme.of(context).primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(top: topMargin),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: isDark ? Border.all(color: darkBorderDefaultColor) : null,
      ),
      child: TextFormField(
        controller: controller,
        // Without minLines, maxLines > 1 reserves every line box up front and
        // the field starts at 76 instead of the Figma 56. With it, the field
        // opens at one line and grows only once the text wraps.
        minLines: 1,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        onTapOutside: onComplete,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: baseStyle?.copyWith(color: scheme.primaryContainer),
        // onEditingComplete: onComplete ?? () {},
        decoration: InputDecoration(
          hintText: UiUtils.getTranslatedLabel(context, hint),
          hintStyle:
              baseStyle?.copyWith(color: scheme.primaryContainer.withOpacity(0.7)),
          border: InputBorder.none,
          // 18 + 20 (body-medium line height) + 18 = 56, the Figma field height.
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
