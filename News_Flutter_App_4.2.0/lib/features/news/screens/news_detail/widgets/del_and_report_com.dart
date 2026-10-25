import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/news/cubits/news_comment/delete_comment_cubit.dart';
import 'package:news/features/news/cubits/news_comment/flag_comment_cubit.dart';
import 'package:news/features/news/cubits/comment_news_cubit.dart';
import 'package:news/features/news/models/comment_model.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/commons/widgets/custom_text_label.dart';

delAndReportCom(
    {required int index,
    required CommentModel model,
    required BuildContext context,
    required TextEditingController reportC,
    required String newsId,
    required StateSetter setState,
    Function? isReplyUpdate}) {
  // Drop focus before the dialog opens so the comment input isn't restored
  // (and the keyboard raised) when the dialog closes.
  FocusManager.instance.primaryFocus?.unfocus();
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            elevation: 2.0,
            // FIGMA(1592-6713 / 1592-6721): card is white in light and the
            // #0E1B36 "dark-card" in dark. `secondary` maps to exactly those
            // (white / darkSecondaryColor); `surface` was #1F345E in dark, which
            // was the wrong (too light) background.
            backgroundColor: UiUtils.getColorScheme(context).secondary,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15.0))),
            content: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // FIGMA(1524-4068): redesigned "Delete Comment" confirmation -
                // a centered title + message and equal-width No (outlined) +
                // Yes, Delete (filled, app primary) buttons. Text and the
                // outlined button use the theme-aware primaryContainer, same as
                // the report dialog.
                if (context.read<AuthCubit>().getUserId() == model.userId!)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Title
                      CustomTextLabel(
                        text: 'deleteComment',
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer,
                                fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      // Confirmation message
                      CustomTextLabel(
                        text: 'deleteCommentMsg',
                        textAlign: TextAlign.center,
                        textStyle: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer),
                      ),
                      const SizedBox(height: 28),
                      // No (outlined) + Yes, Delete (filled primary) - equal width
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                side: BorderSide(
                                    color: UiUtils.getColorScheme(context)
                                        .primaryContainer),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: CustomTextLabel(
                                    text: 'noLbl',
                                    maxLines: 1,
                                    softWrap: false,
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color:
                                                UiUtils.getColorScheme(context)
                                                    .primaryContainer)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BlocConsumer<DeleteCommCubit,
                                    DeleteCommState>(
                                bloc: context.read<DeleteCommCubit>(),
                                listener: (context, state) {
                                  if (state is DeleteCommSuccess) {
                                    context
                                        .read<CommentNewsCubit>()
                                        .deleteComment(index);
                                    showSnackBar(state.message, context);
                                    if (isReplyUpdate != null) {
                                      isReplyUpdate(false, index);
                                    }
                                    Navigator.pop(context);
                                    // Focus is restored by the route after the
                                    // pop, so drop it (and hide the IME) on the
                                    // next frame, after that restore has run.
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      SystemChannels.textInput
                                          .invokeMethod('TextInput.hide');
                                    });
                                  }
                                },
                                builder: (context, state) {
                                  return ElevatedButton(
                                    onPressed: () {
                                      if (context
                                              .read<AuthCubit>()
                                              .getUserId() !=
                                          "0") {
                                        context
                                            .read<DeleteCommCubit>()
                                            .setDeleteComm(commId: model.id!);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      elevation: 0,
                                      // App primary (red) in both themes, with
                                      // white text so it stays readable.
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: CustomTextLabel(
                                          text: 'yesDelete',
                                          maxLines: 1,
                                          softWrap: false,
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(color: Colors.white)),
                                    ),
                                  );
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
                // FIGMA(1524-4109): redesigned "Report Comment" dialog - a
                // centered title, a rounded hint field ("eg. This is fake") and
                // equal-width Cancel (outlined) + Submit (filled, app primary)
                // buttons. Text and the outlined button use `primaryContainer`
                // (navy in light / white in dark) so contrast adapts to themes.
                if (context.read<AuthCubit>().getUserId() != model.userId!)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Title
                      CustomTextLabel(
                        text: 'reportComment',
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer,
                                fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      // Reason field with hint placeholder
                      TextField(
                        controller: reportC,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer),
                        decoration: InputDecoration(
                          isDense: true,
                          // FIGMA(1592-6721): field is a white@20% panel with a
                          // white@10% border in dark. A white overlay reads as
                          // solid white on the white card in light mode and as
                          // the design's translucent panel on the #0E1B36 card
                          // in dark mode, so it stays defined in both themes.
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          hintText:
                              UiUtils.getTranslatedLabel(context, 'reportHint'),
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer
                                      .withOpacity(0.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer
                                      .withOpacity(0.1))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer
                                      .withOpacity(0.3))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cancel (outlined) + Submit (filled primary) - equal width
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                side: BorderSide(
                                    color: UiUtils.getColorScheme(context)
                                        .primaryContainer),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              child: CustomTextLabel(
                                  text: 'cancelBtn',
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .primaryContainer)),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: BlocConsumer<SetFlagCubit, SetFlagState>(
                                bloc: context.read<SetFlagCubit>(),
                                listener: (context, state) {
                                  if (state is SetFlagFetchSuccess) {
                                    setState(() => reportC.text = "");
                                    showSnackBar(state.message, context);
                                    Navigator.pop(context);
                                  }
                                },
                                builder: (context, state) {
                                  return ElevatedButton(
                                    onPressed: () {
                                      if (context
                                              .read<AuthCubit>()
                                              .getUserId() !=
                                          "0") {
                                        if (reportC.text.trim().isNotEmpty) {
                                          context.read<SetFlagCubit>().setFlag(
                                              commId: model.id!,
                                              newsId: newsId,
                                              message: reportC.text);
                                        } else {
                                          showSnackBar(
                                              UiUtils.getTranslatedLabel(
                                                  context, 'firstFillData'),
                                              context);
                                        }
                                      } else {
                                        UiUtils.loginRequired(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      elevation: 0,
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    child: CustomTextLabel(
                                        text: 'submitBtn',
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: Colors.white)),
                                  );
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            )));
      });
}
