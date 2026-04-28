import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// ✅ Put delegate class FIRST before AppLocalizations
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localization = AppLocalizations(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ✅ Now AppLocalizations comes after
class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  // ✅ Now it can find _AppLocalizationsDelegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<bool> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/lang/${locale.languageCode}.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map(
          (key, value) => MapEntry(key, value.toString()),
    );
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // ========== Auth related translations ==========
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get name => translate('name');
  String get phoneNumber => translate('phone_number');
  String get gender => translate('gender');
  String get birthDate => translate('birth_date');
  String get country => translate('country');
  String get googleId => translate('google_id');
  String get verificationCode => translate('verification_code');
  String get male => translate('male');
  String get female => translate('female');

  // ========== Button texts ==========
  String get continueText => translate('continue');
  String get loginButton => translate('login_button');
  String get registerButton => translate('register_button');
  String get verifyButton => translate('verify_button');
  String get resendCode => translate('resend_code');
  String get continueWithGoogle => translate('continue_with_google');
  String get registerWithGoogle => translate('register_with_google');
  String get cancel => translate('cancel');
  String get retry => translate('retry');

  // ========== Messages ==========
  String get loginSubtitle => translate('login_subtitle');
  String get registerSubtitle => translate('register_subtitle');
  String get verificationSubtitle => translate('verification_subtitle');
  String get or => translate('or');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get enterPasswordTitle => translate('enter_password_title');
  String get forgotPassword => translate('forgot_password');

  // ========== Validation messages ==========
  String get invalidEmail => translate('invalid_email');
  String get invalidPassword => translate('invalid_password');
  String get passwordsDontMatch => translate('passwords_dont_match');
  String get fieldRequired => translate('field_required');
  String get selectBirthDate => translate('select_birth_date');

  // ========== Success/Error messages ==========
  String get loginSuccess => translate('login_success');
  String get registerSuccess => translate('register_success');
  String get verificationSuccess => translate('verification_success');
  String get googleSignInFailed => translate('google_sign_in_failed');
  String get googleSignInCancelled => translate('google_sign_in_cancelled');
  String get googleSignInNotConfigured => translate('google_sign_in_not_configured');
  String get featureComingSoon => translate('feature_coming_soon');
  String get editProfileNotImplemented => translate('edit_profile_not_implemented');

  // ========== Navigation ==========
  String get home => translate('home');
  String get explore => translate('explore');
  String get profile => translate('profile');
  String get settings => translate('settings');

  // ========== Settings & Actions ==========
  String get favorites => translate('favorites');
  String get history => translate('history');
  String get wallet => translate('wallet');
  String get account => translate('account');
  String get contactUs => translate('contact_us');
  String get preferences => translate('preferences');
  String get accountActions => translate('account_actions');
  String get logout => translate('logout');
  String get logoutConfirmation => translate('logout_confirmation');
  String get lightMode => translate('light_mode');
  String get darkMode => translate('dark_mode');
  String get toggleTheme => translate('toggle_theme');
  String get toggleLanguage => translate('toggle_language');
  String get chooseLanguage => translate('choose_language');
  String get english => translate('english');
  String get arabic => translate('arabic');

  // ========== Role Selection ==========
  String get continueAs => translate('continue_as');
  String get tourist => translate('tourist');
  String get guide => translate('helper');
  String get selectRole => translate('select_role');

  // ========== App ==========
  String get appTitle => translate('app_title');

  // ========== Instant booking (tourist) ==========
  String get bookingInstantPlanTitle => translate('booking_instant_plan_title');
  String get bookingInstantPlanSubtitle =>
      translate('booking_instant_plan_subtitle');
  String get bookingInstantFindHelpers =>
      translate('booking_instant_find_helpers');
  String get bookingInstantValidationSnackbar =>
      translate('booking_instant_validation_snackbar');

  String get bookingReviewTitle => translate('booking_review_title');
  String get bookingReviewSubtitle => translate('booking_review_subtitle');
  String get bookingReviewPaymentTitle =>
      translate('booking_review_payment_title');
  String get bookingReviewPayCash => translate('booking_review_pay_cash');
  String get bookingReviewPayCard => translate('booking_review_pay_card');
  String get bookingReviewValidationSnackbar =>
      translate('booking_review_validation_snackbar');
  String get bookingReviewConfirm => translate('booking_review_confirm');
  String get bookingReviewConfirmLoading =>
      translate('booking_review_confirm_loading');
  String get bookingReviewItinerary => translate('booking_review_itinerary');
  String get bookingReviewTripDetails =>
      translate('booking_review_trip_details');
  String get bookingReviewPriceBreakdown =>
      translate('booking_review_price_breakdown');
  String get bookingReviewEstimatedTotal =>
      translate('booking_review_estimated_total');
  String get bookingReviewNotes => translate('booking_review_notes');
  String get bookingReviewPickupLabel =>
      translate('booking_review_pickup_label');
  String get bookingReviewDestinationLabel =>
      translate('booking_review_destination_label');
  String get bookingReviewDuration => translate('booking_review_duration');
  String get bookingReviewTravelers => translate('booking_review_travelers');
  String get bookingReviewLanguage => translate('booking_review_language');
  String get bookingReviewCar => translate('booking_review_car');
  String get bookingReviewYes => translate('booking_review_yes');
  String get bookingReviewNo => translate('booking_review_no');
  String get bookingReviewPriceRetry => translate('booking_review_price_retry');
  String get bookingReviewPriceUnavailable =>
      translate('booking_review_price_unavailable');
}
