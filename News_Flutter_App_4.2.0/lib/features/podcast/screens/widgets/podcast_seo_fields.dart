// Optional SEO block of the Create / Edit channel form: meta title,
// description, keywords and schema markup. None of them are validated.

import 'package:flutter/material.dart';
import 'package:news/features/add_edit_news/widgets/app_text_file.dart';
import 'package:news/features/podcast/screens/podcast_form_controller.dart';

class PodcastSeoFields extends StatelessWidget {
  final PodcastFormController controller;

  const PodcastSeoFields({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
            controller: controller.metaTitle,
            hint: 'metaTitleLbl',
            floatingLabel: true,
            topMargin: 0),
        const SizedBox(height: 12),
        AppTextField(
            controller: controller.metaDescription,
            hint: 'metaDescriptionLbl',
            floatingLabel: true,
            topMargin: 0,
            maxLines: 2),
        const SizedBox(height: 12),
        AppTextField(
            controller: controller.metaKeyword,
            hint: 'metaKeywordLbl',
            floatingLabel: true,
            topMargin: 0),
        const SizedBox(height: 12),
        AppTextField(
            controller: controller.schemaMarkup,
            hint: 'schemaMarkupLbl',
            floatingLabel: true,
            topMargin: 0,
            maxLines: 4),
        const SizedBox(height: 12),
      ],
    );
  }
}
