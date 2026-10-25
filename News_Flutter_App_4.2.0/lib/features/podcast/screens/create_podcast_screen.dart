// Create / Edit channel form (Routes.createPodcast); passing a PodcastModel turns
// it into the Edit form. Pops `true` after a save. Publishing obeys auto_approve.
//
// All form state lives in [PodcastFormController]; the fields themselves are
// built from the widgets in screens/widgets/.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/features/add_edit_news/widgets/app_text_file.dart';
import 'package:news/features/add_edit_news/widgets/selection_widget.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/podcast/cubits/manage_podcast_cubit.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/screens/podcast_form_controller.dart';
import 'package:news/features/podcast/screens/widgets/podcast_deactive_notice.dart';
import 'package:news/features/podcast/screens/widgets/podcast_form_action_buttons.dart';
import 'package:news/features/podcast/screens/widgets/podcast_form_app_bar.dart';
import 'package:news/features/podcast/screens/widgets/podcast_image_picker_field.dart';
import 'package:news/features/podcast/screens/widgets/podcast_image_source_sheet.dart';
import 'package:news/features/podcast/screens/widgets/podcast_publish_date_picker.dart';
import 'package:news/features/podcast/screens/widgets/podcast_seo_fields.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/utils/validators.dart';

class CreatePodcastScreen extends StatefulWidget {
  final PodcastModel? podcast;

  const CreatePodcastScreen({super.key, this.podcast});

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>?;
    return CupertinoPageRoute(
        builder: (_) => CreatePodcastScreen(
            podcast: arguments?['podcast'] as PodcastModel?));
  }

  @override
  State<CreatePodcastScreen> createState() => _CreatePodcastScreenState();
}

class _CreatePodcastScreenState extends State<CreatePodcastScreen> {
  late final PodcastFormController _form =
      PodcastFormController(podcast: widget.podcast);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- handlers

  void _onTitleChanged(String value) {
    if (_form.syncSlugWithTitle(value)) setState(() {});
  }

  void _onSlugChanged(String value) => setState(_form.normalizeSlug);

  void _pickImage() {
    showPodcastImageSourceSheet(
        context: context,
        onImagePicked: (file) => setState(() => _form.image = file));
  }

  Future<void> _pickPublishDate() async {
    final DateTime now = DateTime.now();
    final DateTime lastDate = DateTime(now.year + 1);
    // The picker asserts on an initialDate outside [firstDate, lastDate], and a
    // saved podcast can carry a publish date from outside that window.
    final DateTime selected = _form.publishDate ?? now;
    final DateTime initialDate = selected.isBefore(now)
        ? now
        : (selected.isAfter(lastDate) ? lastDate : selected);
    final DateTime? pickedDate = await showPodcastPublishDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now,
        lastDate: lastDate);
    if (pickedDate == null) return;
    setState(() => _form.publishDate = pickedDate);
  }

  void _submit({required bool isDraft}) {
    FocusScope.of(context).unfocus();
    if (!_form.formKey.currentState!.validate()) return;
    if (_form.publishDate == null) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzSelPublishDateLbl'), context);
      return;
    }
    if (_form.image == null && !_form.isEdit) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzAddMainImageLbl'), context);
      return;
    }

    final bool autoApprove = context.read<AuthCubit>().isAuthorAutoApprove();
    _form.heldForApproval = !isDraft && !autoApprove;

    context.read<ManagePodcastCubit>().savePodcast(
          podcastId: widget.podcast?.id,
          title: _form.title.text.trim(),
          slug: _form.slug.text.trim(),
          description: _form.description.text.trim(),
          publishDate: _form.publishDate!,
          isDraft: isDraft,
          metaTitle: _form.metaTitle.text.trim(),
          metaKeyword: _form.metaKeyword.text,
          metaDescription: _form.metaDescription.text.trim(),
          schemaMarkup: _form.schemaMarkup.text.trim(),
          image: _form.image,
        );
  }

  void _onSaveState(BuildContext context, ManagePodcastState state) {
    if (state is ManagePodcastSuccess) {
      showSnackBar(
          _form.heldForApproval
              ? UiUtils.getTranslatedLabel(context, 'podcastPendingApprovalMsg')
              : state.message,
          context);
      Navigator.of(context).pop(true);
    }
    if (state is ManagePodcastFailure) {
      showSnackBar(state.errorMessage, context);
    }
  }

  // -------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PodcastFormAppBar(
          titleKey: _form.isEdit ? 'editPodcastLbl' : 'createPodcastLbl'),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _form.formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.podcast?.isActive == false) ...[
                      const PodcastDeactiveNotice(),
                      const SizedBox(height: 12),
                    ],
                    AppTextField(
                        controller: _form.title,
                        hint: 'podcastTitleLbl',
                        floatingLabel: true,
                        topMargin: 0,
                        onChanged: _onTitleChanged,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? UiUtils.getTranslatedLabel(
                                    context, 'podcastTitleReqLbl')
                                : null),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _form.slug,
                        hint: 'slugLbl',
                        floatingLabel: true,
                        topMargin: 0,
                        validator: (value) =>
                            Validators.slugValidation(value ?? '', context),
                        onChanged: _onSlugChanged),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _form.description,
                        hint: 'podcastDescLbl',
                        floatingLabel: true,
                        topMargin: 0,
                        maxLines: 4,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? UiUtils.getTranslatedLabel(
                                    context, 'podcastDescReqLbl')
                                : null),
                    const SizedBox(height: 12),
                    SelectionField(
                        isDate: true,
                        topMargin: 0,
                        value: (_form.publishDate == null)
                            ? ''
                            : DateFormat('dd-MM-yyyy')
                                .format(_form.publishDate!),
                        placeholder:
                            UiUtils.getTranslatedLabel(context, 'publishDate'),
                        onTap: _pickPublishDate),
                    const SizedBox(height: 12),
                    PodcastImagePickerField(
                        pickedImage: _form.image,
                        existingImageUrl: _form.existingImageUrl,
                        onTap: _pickImage),
                    const SizedBox(height: 12),
                    PodcastSeoFields(controller: _form),
                  ],
                ),
              ),
            ),
          ),
          BlocConsumer<ManagePodcastCubit, ManagePodcastState>(
            listener: _onSaveState,
            builder: (context, state) => PodcastFormActionButtons(
                isSaving: state is ManagePodcastInProgress,
                onSaveDraft: () => _submit(isDraft: true),
                onPublish: () => _submit(isDraft: false)),
          ),
        ],
      ),
    );
  }
}
