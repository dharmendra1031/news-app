import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_plus/html_editor.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/add_edit_news/widgets/gemini_service.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:shimmer/shimmer.dart';

class NewsDescription extends StatefulWidget {
  String? description;
  Function changeDesc;
  Function? validateDesc;
  int? from;
  String? summDescription;
  Function? isDraftNews;

  NewsDescription(this.description, this.summDescription, this.changeDesc,
      this.validateDesc, this.from, this.isDraftNews,
      {super.key});

  @override
  NewsDescriptionState createState() => NewsDescriptionState();
}

class NewsDescriptionState extends State<NewsDescription> {
  String result = '';
  bool isLoading = true;
  bool isSubmitted = false;
  bool _hasSetInitialDescription = false;
  bool _isSummarizing = false;

  final HtmlEditorController controller = HtmlEditorController();

  final TextEditingController summaryController = TextEditingController();

  @override
  void initState() {
    setValue();
    super.initState();
  }

  setValue() async {
    Future.delayed(
      const Duration(seconds: 4),
      () {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      },
    );
  }

  getAppBar() {
    return PreferredSize(
        preferredSize: const Size(double.infinity, 45),
        child: UiUtils.applyBoxShadow(
          context: context,
          child: AppBar(
            centerTitle: false,
            backgroundColor: Colors.transparent,
            title: Transform(
              transform: Matrix4.translationValues(-20.0, 0.0, 0.0),
              child: CustomTextLabel(
                text: widget.from == 2 ? 'editNewsLbl' : 'createNewsLbl',
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: UiUtils.getColorScheme(context).primaryContainer,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InkWell(
                onTap: () async {
                  final value = await _readEditorText();
                  if (!mounted) return;
                  widget.changeDesc(value ?? '', summaryController.text, false);
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Icon(Icons.arrow_back,
                    color: UiUtils.getColorScheme(context).primaryContainer),
              ),
            ),
            actions: [
              Container(
                padding: const EdgeInsetsDirectional.only(end: 20),
                alignment: Alignment.center,
                child: CustomTextLabel(
                    text: 'step2of2Lbl',
                    textStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: UiUtils.getColorScheme(context)
                            .primaryContainer
                            .withOpacity(0.6))),
              )
            ],
          ),
        ));
  }

  Widget nextBtn() {
    return (isSubmitted)
        ? UiUtils.showCircularProgress(true, Theme.of(context).primaryColor)
        : Padding(
            padding: const EdgeInsetsDirectional.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: InkWell(
                  onTap: () => validateTextAndSubmit(isDraft: 1),
                  splashColor: Colors.transparent,
                  child: Container(
                      height: 45.0,
                      width: MediaQuery.of(context).size.width * 0.4,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.0),
                        border: Border.all(
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer),
                      ),
                      child: CustomTextLabel(
                          text: 'saveAsDraftLbl',
                          textStyle: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.6))),
                )),
                SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    splashColor: Colors.transparent,
                    child: Container(
                      height: 45.0,
                      width: MediaQuery.of(context).size.width * 0.4,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color:
                              UiUtils.getColorScheme(context).primaryContainer,
                          borderRadius: BorderRadius.circular(7.0)),
                      child: CustomTextLabel(
                        text: 'publishBtnLbl',
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                color: UiUtils.getColorScheme(context).surface,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 0.6),
                      ),
                    ),
                    onTap: () => validateTextAndSubmit(isDraft: 0),
                  ),
                ),
              ],
            ),
          );
  }

  /// The editor's webview only exists once the shimmer is gone and the page
  /// has loaded; calling getText() before that throws. Returns null then.
  Future<String?> _readEditorText() async {
    if (isLoading) return null;
    try {
      return await controller.getText();
    } catch (_) {
      return null;
    }
  }

  Future<void> validateTextAndSubmit({required int isDraft}) async {
    final value = await _readEditorText();
    if (value == null || !mounted) return; // editor still loading
    widget.isDraftNews!(isDraft);
    setState(() => isSubmitted = true);
    widget.validateDesc!(value, summaryController.text);
  }

  Widget shimmer() {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.741,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).cardColor),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(),
      bottomNavigationBar: nextBtn(),
      body: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          // canPop is false, so a system back press arrives with didPop ==
          // false and should hand the text back to the form. didPop == true
          // means the whole screen was popped programmatically (e.g. after a
          // successful submit) and the parent is going away, so there is
          // nothing to hand back to.
          if (didPop) return;
          _readEditorText().then((value) {
            if (!mounted) return;
            widget.changeDesc(value ?? '', summaryController.text, false);
          });
        },
        child: GestureDetector(
            onTap: () {
              if (!kIsWeb) {
                FocusScope.of(context).unfocus(); //dismiss keyboard
              }
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.all(20),
              child: isLoading
                  ? shimmer()
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                  textTheme: TextTheme(
                                      titleSmall: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(color: Colors.orange))),
                              child: HtmlEditor(
                                controller: controller,
                                htmlEditorOptions: HtmlEditorOptions(
                                    hint: UiUtils.getTranslatedLabel(
                                        context, 'descLbl'),
                                    adjustHeightForKeyboard: true,
                                    autoAdjustHeight: true,
                                    shouldEnsureVisible: true,
                                    spellCheck: true,
                                    disabled: false),
                                htmlToolbarOptions: HtmlToolbarOptions(
                                  toolbarPosition: ToolbarPosition.aboveEditor,
                                  toolbarType: ToolbarType.nativeExpandable,
                                  gridViewHorizontalSpacing: 0,
                                  gridViewVerticalSpacing: 0,
                                  toolbarItemHeight: 30,
                                  buttonColor: UiUtils.getColorScheme(context)
                                      .primaryContainer,
                                  buttonFocusColor:
                                      Theme.of(context).primaryColor,
                                  buttonBorderColor: Colors.red,
                                  buttonFillColor: secondaryColor,
                                  dropdownIconColor:
                                      Theme.of(context).primaryColor,
                                  dropdownIconSize: 26,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .primaryContainer),
                                  onButtonPressed: (ButtonType type,
                                      bool? status, Function? updateStatus) {
                                    return true;
                                  },
                                  onDropdownChanged: (DropdownType type,
                                      dynamic changed,
                                      Function(dynamic)? updateSelectedItem) {
                                    return true;
                                  },
                                  mediaLinkInsertInterceptor:
                                      (String url, InsertFileType type) {
                                    return true;
                                  },
                                  mediaUploadInterceptor: (PlatformFile file,
                                      InsertFileType type) async {
                                    return true;
                                  },
                                ),
                                otherOptions: OtherOptions(
                                  height: MediaQuery.of(context).size.height *
                                      0.725,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color:
                                        UiUtils.getColorScheme(context).surface,
                                  ),
                                ),
                                callbacks: Callbacks(
                                  onInit: () {
                                    // Only set the initial description once,
                                    // after the editor is fully loaded.
                                    if (!_hasSetInitialDescription &&
                                        widget.description != null &&
                                        widget.description!.isNotEmpty) {
                                      controller.setText(widget.description!);
                                      _hasSetInitialDescription = true;
                                    }
                                  },
                                  onChangeCodeview: (String? changed) {
                                    result = changed!;
                                  },
                                  onImageUploadError: (
                                    FileUpload? file,
                                    String? base64Str,
                                    UploadError error,
                                  ) {},
                                  onNavigationRequestMobile: (String url) {
                                    return NavigationActionPolicy.ALLOW;
                                  },
                                ),
                              ),
                            ),
                          ),
                          summarySection()
                        ],
                      ),
                    ),
            )),
      ),
    );
  }

  Widget summarySection() {
    if (widget.summDescription != null && widget.summDescription!.isNotEmpty)
      summaryController.text = widget.summDescription!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        CustomTextLabel(
            text: UiUtils.getTranslatedLabel(context, 'summarizedDescription'),
            textStyle: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        TextField(
            controller: summaryController,
            maxLines: 3,
            readOnly: true,
            decoration: InputDecoration(
                hintText: UiUtils.getTranslatedLabel(
                    context, 'clickSummarizeDescription'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: Theme.of(context).brightness == Brightness.dark
                      ? const BorderSide(color: darkBorderDefaultColor)
                      : const BorderSide(),
                ),
                filled: true,
                contentPadding: EdgeInsets.all(5),
                fillColor: UiUtils.getColorScheme(context).surface)),
        const SizedBox(height: 10),
        Center(
          child: ElevatedButton(
            onPressed: _isSummarizing
                ? null
                : () async {
                    String fullText = await controller.getText();

                    if (fullText.trim().isEmpty) {
                      return showSnackBar('enterDescriptionFirst', context);
                    }

                    setState(() {
                      _isSummarizing = true;
                    });

                    try {
                      String summary =
                          await GeminiService.summarizeDescription(fullText);

                      if (!mounted) return;

                      setState(() {
                        summaryController.text = summary;
                      });
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSummarizing = false;
                        });
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: UiUtils.getColorScheme(context).primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: _isSummarizing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: UiUtils.getColorScheme(context).surface,
                    ),
                  )
                : Text(
                    UiUtils.getTranslatedLabel(
                      context,
                      'summarizedDescription',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: UiUtils.getColorScheme(context).surface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
          ),
        )
      ],
    );
  }
}
