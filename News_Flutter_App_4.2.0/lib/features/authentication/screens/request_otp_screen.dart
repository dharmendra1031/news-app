import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/utils/validators.dart';

class RequestOtp extends StatefulWidget {
  const RequestOtp({super.key});

  @override
  RequestOtpState createState() => RequestOtpState();
}

class RequestOtpState extends State<RequestOtp> {
  TextEditingController phoneC = TextEditingController();
  String? phone, conCode;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool isLoading = false;
  Country? selectedCountry;
  String? verificationId;
  String errorMessage = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int forceResendingToken = 0;

  @override
  void initState() {
    super.initState();
    // Fallback default (India) until we pull the server/app-configured country.
    selectedCountry = Country.tryParse('IN') ?? Country.parse('IN');
    conCode = selectedCountry!.phoneCode;

    // Update selection from app configuration after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final iso2 =
          context.read<AppConfigurationCubit>().getCountryCode() ?? 'IN';
      final country = Country.tryParse(iso2) ?? Country.parse('IN');
      if (!mounted) return;
      setState(() {
        selectedCountry = country;
        conCode = country.phoneCode;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: showContent(),
        ),
        UiUtils.showCircularProgress(isLoading, Theme.of(context).primaryColor)
      ],
    ));
  }

  //show form content
  showContent() {
    return Container(
      padding: const EdgeInsetsDirectional.all(20.0),
      child: SingleChildScrollView(
          child: Form(
              key: _formkey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                        //backButton
                        alignment: Alignment.topLeft,
                        child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            splashColor: Colors.transparent,
                            child:
                                const Icon(Icons.keyboard_backspace_rounded))),
                    const SizedBox(height: 50),
                    otpVerifySet(),
                    enterMblSet(),
                    receiveDigitSet(),
                    setCodeWithMono(),
                    reqOtpBtn()
                  ]))),
    );
  }

  otpVerifySet() {
    return CustomTextLabel(
        text: 'loginLbl',
        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: UiUtils.getColorScheme(context).primaryContainer,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
        textAlign: TextAlign.center);
  }

  enterMblSet() {
    return Padding(
      padding: const EdgeInsets.only(top: 35.0),
      child: CustomTextLabel(
        text: 'enterMblLbl',
        textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: UiUtils.getColorScheme(context).primaryContainer,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  receiveDigitSet() {
    return Container(
      padding: const EdgeInsets.only(top: 20.0),
      child: CustomTextLabel(
          text: 'receiveDigitLbl',
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: UiUtils.getColorScheme(context)
                  .primaryContainer
                  .withOpacity(0.8),
              fontSize: 14),
          textAlign: TextAlign.left),
    );
  }

  setCodeWithMono() {
    return Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Theme.of(context).colorScheme.surface),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[setCountryCode(), setMono()],
            )));
  }

  setCountryCode() {
    return SizedBox(
      height: 45,
      child: InkWell(
        onTap: () async {
          FocusScope.of(context)
              .unfocus(); // Dismiss keyboard before opening picker.
          showCountryPicker(
            context: context,
            showPhoneCode: true,
            onSelect: (Country country) {
              setState(() {
                selectedCountry = country;
                // Firebase expects phone number in international format; VerifyOtp adds the '+' itself.
                conCode = country.phoneCode;
              });
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsetsDirectional.only(start: 16.0, end: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  selectedCountry?.flagEmoji ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 55.0,
                height: 45.0,
                alignment: Alignment.center,
                child: CustomTextLabel(
                  text: conCode ?? '',
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: UiUtils.getColorScheme(context)
                            .primaryContainer
                            .withOpacity(0.7),
                      ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  setMono() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 5.0, bottom: 15.0),
        child: Container(
            height: 40,
            width: MediaQuery.of(context).size.width * 0.57,
            alignment: Alignment.center,
            child: TextFormField(
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              controller: phoneC,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: UiUtils.getColorScheme(context)
                      .primaryContainer
                      .withOpacity(0.7)),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (val) => Validators.mobValidation(val!, context),
              onSaved: (String? value) => phone = value,
              decoration: InputDecoration(
                hintText: UiUtils.getTranslatedLabel(context, 'enterMblLbl'),
                hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: UiUtils.getColorScheme(context)
                        .primaryContainer
                        .withOpacity(0.5)),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            )),
      ),
    );
  }

  Future<void> verifyPhone(BuildContext context) async {
    try {
      final dialCode = (conCode ?? '').replaceAll('+', '');
      await _auth.verifyPhoneNumber(
          phoneNumber: "+$dialCode${phoneC.text.trim()}",
          verificationCompleted: (AuthCredential phoneAuthCredential) {
            showSnackBar(phoneAuthCredential.toString(), context);
          },
          verificationFailed: (FirebaseAuthException exception) {
            setState(() => isLoading = false);
            if (exception.code == "invalid-phone-number") {
              //invalidPhoneNumber
              showSnackBar(
                  UiUtils.getTranslatedLabel(context, 'invalidPhoneNumber'),
                  context);
            } else {
              showSnackBar('${exception.message}', context);
            }
          },
          forceResendingToken: forceResendingToken,
          codeAutoRetrievalTimeout: (String verId) => verificationId = verId,
          codeSent: processCodeSent(),
          //smsOTPSent
          timeout: const Duration(seconds: 60));
    } on FirebaseAuthException catch (authError) {
      setState(() => isLoading = false);
      showSnackBar(authError.message!, context);
    } on FirebaseException catch (e) {
      setState(() => isLoading = false);
      showSnackBar(e.toString(), context);
    } catch (e) {
      setState(() => isLoading = false);
      showSnackBar(e.toString(), context);
    }
  }

  processCodeSent() {
    try {
      smsOTPSent(String? verId, [int? forceCodeResend]) async {
        if (forceCodeResend != null) forceResendingToken = forceCodeResend;
        verificationId = verId;
        setState(() => isLoading = false);
        showSnackBar(UiUtils.getTranslatedLabel(context, 'codeSent'), context);
        await Navigator.of(context).pushNamed(Routes.verifyOtp, arguments: {
          "verifyId": verificationId,
          "countryCode": conCode,
          "mono": phoneC.text.trim()
        });
      }

      return smsOTPSent;
    } catch (e) {
      //debugPrint("issue in otp - ${e.toString()}");
    }
  }

  reqOtpBtn() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 60.0),
      child: InkWell(
        child: Container(
            height: 45.0,
            width: MediaQuery.of(context).size.width * 0.9,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(7.0)),
            child: CustomTextLabel(
                text: 'reqOtpLbl',
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 16))),
        onTap: () async {
          FocusScope.of(context).unfocus(); //dismiss keyboard
          if (validateAndSave()) {
            if (await InternetConnectivity.isNetworkAvailable()) {
              setState(() => isLoading = true);
              verifyPhone(context);
            } else {
              showSnackBar(
                  UiUtils.getTranslatedLabel(context, 'internetmsg'), context);
            }
          }
        },
      ),
    );
  }

  //check validation of form data
  bool validateAndSave() {
    final form = _formkey.currentState;
    form!.save();
    return (form.validate()) ? true : false;
  }
}
