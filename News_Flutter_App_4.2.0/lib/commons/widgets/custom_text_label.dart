import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/language/cubits/language_json_cubit.dart';

class CustomTextLabel extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  /// When true, collapses any run of whitespace (including stray line breaks
  /// coming from the remote language data) into a single space. Use for
  /// headings that must stay on one line regardless of the translated value.
  final bool collapseWhitespace;

  const CustomTextLabel(
      {super.key,
      required this.text,
      this.textStyle,
      this.textAlign,
      this.maxLines,
      this.overflow,
      this.softWrap,
      this.collapseWhitespace = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageJsonCubit, LanguageJsonState>(
      builder: (context, state) {
        var label = context.read<LanguageJsonCubit>().getTranslatedLabels(text);
        if (collapseWhitespace) {
          label = label.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        return Text(label,
            maxLines: maxLines,
            overflow: overflow,
            softWrap: softWrap,
            style: textStyle,
            textAlign: textAlign);
      },
    );
  }
}
