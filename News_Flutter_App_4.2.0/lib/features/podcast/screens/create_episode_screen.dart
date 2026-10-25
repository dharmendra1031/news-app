// Create / Edit episode form (Routes.createEpisode); [episode] null = create.
// Pops `true` after a save so the list behind reloads.
//
// All form state lives in [EpisodeFormController]; the fields themselves are
// built from the widgets in screens/widgets/.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/features/add_edit_news/widgets/app_text_file.dart';
import 'package:news/features/add_edit_news/widgets/selection_widget.dart';
import 'package:news/features/podcast/cubits/manage_episode_cubit.dart';
import 'package:news/features/podcast/models/episode_model.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/screens/episode_form_controller.dart';
import 'package:news/features/podcast/screens/widgets/episode_audio_picker_field.dart';
import 'package:news/features/podcast/screens/widgets/episode_source_type_selector.dart';
import 'package:news/features/podcast/screens/widgets/podcast_deactive_notice.dart';
import 'package:news/features/podcast/screens/widgets/podcast_form_action_buttons.dart';
import 'package:news/features/podcast/screens/widgets/podcast_form_app_bar.dart';
import 'package:news/features/podcast/screens/widgets/podcast_image_picker_field.dart';
import 'package:news/features/podcast/screens/widgets/podcast_image_source_sheet.dart';
import 'package:news/features/podcast/screens/widgets/podcast_publish_date_picker.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/utils/validators.dart';

class CreateEpisodeScreen extends StatefulWidget {
  final PodcastModel podcast;

  final EpisodeModel? episode;

  const CreateEpisodeScreen({super.key, required this.podcast, this.episode});

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => CreateEpisodeScreen(
            podcast: arguments['podcast'] as PodcastModel,
            episode: arguments['episode'] as EpisodeModel?));
  }

  @override
  State<CreateEpisodeScreen> createState() => _CreateEpisodeScreenState();
}

class _CreateEpisodeScreenState extends State<CreateEpisodeScreen> {
  late final EpisodeFormController _form = EpisodeFormController(
      podcast: widget.podcast, episode: widget.episode);

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

  void _onSourceTypeSelected(EpisodeSourceType source) {
    if (_form.selectSourceType(source)) setState(() {});
  }

  void _pickImage() {
    showPodcastImageSourceSheet(
        context: context,
        onImagePicked: (file) => setState(() => _form.image = file));
  }

  Future<void> _pickAudio() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: EpisodeFormController.allowedAudioExtensions);
    final String? path = result?.files.single.path;
    if (path == null || !mounted) return;
    final File audio = File(path);
    if (!_form.isSupportedAudio(audio)) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzValidAudioFileLbl'), context);
      return;
    }
    setState(() => _form.audio = audio);
  }

  Future<void> _pickPublishDate() async {
    final DateTime now = DateTime.now();
    final DateTime lastDate = DateTime(now.year + 1);
    // The picker asserts on an initialDate outside [firstDate, lastDate], and a
    // saved episode can carry a publish date from outside that window.
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

  String? _episodeNoValidator(String? value) {
    final String episodeNo = (value ?? '').trim();
    if (episodeNo.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'episodeNoReqLbl');
    }
    final int? parsed = int.tryParse(episodeNo);
    if (parsed == null || parsed <= 0) {
      return UiUtils.getTranslatedLabel(context, 'plzValidEpisodeNoLbl');
    }
    return null;
  }

  void _submit({required bool isDraft}) {
    FocusScope.of(context).unfocus();
    if (!_form.formKey.currentState!.validate()) return;
    if (_form.publishDate == null) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzSelPublishDateLbl'), context);
      return;
    }
    if (_form.sourceType == null) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzSelSourceTypeLbl'), context);
      return;
    }
    if (_form.sourceType == EpisodeSourceType.upload &&
        _form.audio == null &&
        !_form.hasSavedAudio) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzUploadAudioLbl'), context);
      return;
    }
    if (_form.image == null && !_form.isEdit) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzAddMainImageLbl'), context);
      return;
    }

    context.read<ManageEpisodeCubit>().saveEpisode(
          episodeId: widget.episode?.id,
          podcastId: widget.podcast.id ?? '',
          episodeNo: _form.episodeNo.text.trim(),
          title: _form.title.text.trim(),
          slug: _form.slug.text.trim(),
          description: _form.description.text.trim(),
          publishDate: _form.publishDate!,
          sourceType: _form.sourceType!.apiValue,
          isDraft: isDraft,
          audioUrl: _form.youtubeUrl.text.trim(),
          audioFile: _form.audio,
          image: _form.image,
        );
  }

  void _onSaveState(BuildContext context, ManageEpisodeState state) {
    if (state is ManageEpisodeSuccess) {
      showSnackBar(state.message, context);
      Navigator.of(context).pop(true);
    }
    if (state is ManageEpisodeFailure) {
      showSnackBar(state.errorMessage, context);
    }
  }

  // -------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PodcastFormAppBar(
          titleKey: _form.isEdit ? 'editEpisodeLbl' : 'createEpisodeLbl'),
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
                    if (widget.episode?.isActive == false) ...[
                      const PodcastDeactiveNotice(),
                      const SizedBox(height: 12),
                    ],
                    AppTextField(
                        controller: _form.podcastTitle,
                        hint: 'podcastLbl',
                        floatingLabel: true,
                        topMargin: 0,
                        readOnly: true),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _form.episodeNo,
                        hint: 'episodeNoLbl',
                        floatingLabel: true,
                        topMargin: 0,
                        keyboardType: TextInputType.number,
                        validator: _episodeNoValidator),
                    const SizedBox(height: 12),
                    AppTextField(
                        controller: _form.title,
                        hint: 'episodeTitleLbl',
                        floatingLabel: true,
                        topMargin: 0,
                        onChanged: _onTitleChanged,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? UiUtils.getTranslatedLabel(
                                    context, 'episodeTitleReqLbl')
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
                        hint: 'episodeDescLbl',
                        floatingLabel: true,
                        topMargin: 0,
                        maxLines: 4,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? UiUtils.getTranslatedLabel(
                                    context, 'episodeDescReqLbl')
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
                    EpisodeSourceTypeSelector(
                        value: _form.sourceType,
                        onChanged: _onSourceTypeSelected),
                    if (_form.sourceType == EpisodeSourceType.youtubeLink) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                          controller: _form.youtubeUrl,
                          hint: 'youtubeUrlLbl',
                          floatingLabel: true,
                          topMargin: 0,
                          validator: (value) => Validators.youtubeUrlValidation(
                              value ?? '', context)),
                    ],
                    if (_form.sourceType == EpisodeSourceType.upload) ...[
                      const SizedBox(height: 12),
                      EpisodeAudioPickerField(
                          pickedAudio: _form.audio,
                          savedAudioName: _form.savedAudioName,
                          onTap: _pickAudio),
                    ],
                    const SizedBox(height: 12),
                    PodcastImagePickerField(
                        pickedImage: _form.image,
                        existingImageUrl: _form.existingImageUrl,
                        onTap: _pickImage),
                  ],
                ),
              ),
            ),
          ),
          BlocConsumer<ManageEpisodeCubit, ManageEpisodeState>(
            listener: _onSaveState,
            builder: (context, state) => PodcastFormActionButtons(
                isSaving: state is ManageEpisodeInProgress,
                onSaveDraft: () => _submit(isDraft: true),
                onPublish: () => _submit(isDraft: false)),
          ),
        ],
      ),
    );
  }
}
