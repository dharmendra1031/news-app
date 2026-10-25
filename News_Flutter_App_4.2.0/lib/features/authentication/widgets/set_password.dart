import 'package:flutter/material.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/authentication/widgets/field_focus_change.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/utils/validators.dart';

class SetPassword extends StatefulWidget {
  final FocusNode currFocus;
  final FocusNode? nextFocus;
  final TextEditingController passC;
  late String pass;
  final double topPad;
  final bool isLogin;

  SetPassword(
      {super.key,
      required this.currFocus,
      this.nextFocus,
      required this.passC,
      required this.pass,
      required this.topPad,
      required this.isLogin});

  @override
  State<StatefulWidget> createState() {
    return _SetPassState();
  }
}

class _SetPassState extends State<SetPassword> {
  bool isObscure = true;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, StateSetter setStater) {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      return Padding(
        padding: EdgeInsets.only(top: widget.topPad),
        child: TextFormField(
          focusNode: widget.currFocus,
          textInputAction:
              widget.isLogin ? TextInputAction.done : TextInputAction.next,
          controller: widget.passC,
          obscureText: isObscure,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: UiUtils.getColorScheme(context).primaryContainer,
              ),
          validator: (val) => Validators.passValidation(val!, context),
          onFieldSubmitted: (v) {
            if (!widget.isLogin) {
              fieldFocusChange(context, widget.currFocus, widget.nextFocus!);
            }
          },
          onChanged: (String value) {
            widget.pass = value;
            setStater(() {});
          },
          decoration: InputDecoration(
            hintText: UiUtils.getTranslatedLabel(context, 'passLbl'),
            hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: UiUtils.getColorScheme(context)
                      .primaryContainer
                      .withOpacity(0.5),
                ),
            suffixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12.0),
                child: IconButton(
                  icon: isObscure
                      ? Icon(Icons.visibility_off_rounded,
                          size: 20,
                          color: UiUtils.getColorScheme(context)
                              .primaryContainer
                              .withOpacity(0.6))
                      : Icon(Icons.visibility_rounded,
                          size: 20,
                          color: UiUtils.getColorScheme(context)
                              .primaryContainer
                              .withOpacity(0.6)),
                  splashColor: Colors.transparent,
                  onPressed: () {
                    setState(() => isObscure = !isObscure);
                  },
                )),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color:
                      UiUtils.getColorScheme(context).outline.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(4.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: isDark
                  ? const BorderSide(color: darkBorderDefaultColor)
                  : BorderSide.none,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
      );
    });
  }
}
