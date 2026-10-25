// Holds every editable value of the Create / Edit channel form so the screen
// itself keeps a single object instead of a dozen loose fields. Pure state — it
// never touches BuildContext, so the form logic stays testable on its own.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/utils/validators.dart';

class PodcastFormController {
  /// The channel being edited, or null while creating a new one.
  final PodcastModel? podcast;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController title = TextEditingController();
  final TextEditingController slug = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController metaTitle = TextEditingController();
  final TextEditingController metaDescription = TextEditingController();
  final TextEditingController metaKeyword = TextEditingController();
  final TextEditingController schemaMarkup = TextEditingController();

  DateTime? publishDate;
  File? image;

  /// Once the author types their own slug the title stops overwriting it.
  bool slugEditedByHand = false;

  /// Set on the last submit: a publish that the author is not auto-approved for
  /// shows the "waiting for approval" message instead of the API's own.
  bool heldForApproval = false;

  PodcastFormController({this.podcast}) {
    final PodcastModel? source = podcast;
    if (source == null) {
      publishDate = DateTime.now();
      return;
    }
    title.text = source.title ?? '';
    slug.text = source.slug ?? '';
    slugEditedByHand = slug.text.trim().isNotEmpty;
    description.text = source.description ?? '';
    metaTitle.text = source.metaTitle ?? '';
    metaDescription.text = source.metaDescription ?? '';
    metaKeyword.text = source.metaKeyword ?? '';
    schemaMarkup.text = source.schemaMarkup ?? '';
    publishDate = DateTime.tryParse(source.publishedAt ?? '');
  }

  bool get isEdit => podcast != null;

  /// Already uploaded cover, shown until the author picks a new [image].
  String get existingImageUrl => podcast?.image ?? '';

  /// Mirrors the title into the slug until the author edits the slug by hand.
  /// Returns true when the slug actually changed, so the caller only rebuilds
  /// on the keystrokes that matter.
  bool syncSlugWithTitle(String value) {
    if (slugEditedByHand) return false;
    final String generated = Validators.generateSlug(value);
    if (generated == slug.text) return false;
    slug.text = generated;
    return true;
  }

  /// Slugs cannot hold spaces, so they are folded to dashes as they are typed.
  void normalizeSlug() {
    slug.text = slug.text.replaceAll(' ', '-');
    slug.selection =
        TextSelection.fromPosition(TextPosition(offset: slug.text.length));
    slugEditedByHand = slug.text.trim().isNotEmpty;
  }

  void dispose() {
    title.dispose();
    slug.dispose();
    description.dispose();
    metaTitle.dispose();
    metaDescription.dispose();
    metaKeyword.dispose();
    schemaMarkup.dispose();
  }
}
