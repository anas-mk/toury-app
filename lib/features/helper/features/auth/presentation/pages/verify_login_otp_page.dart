import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../helper_location/presentation/cubit/helper_location_cubit.dart';
import '../../data/datasources/helper_local_data_source.dart';
import '../../../helper_bookings/domain/entities/helper_booking_entities.dart';
import '../../../helper_bookings/domain/usecases/helper_bookings_usecases.dart';
import '../cubit/helper_auth_cubit.dart';
import '../cubit/helper_auth_state.dart';

class VerifyLoginOtpPage extends StatefulWidget {
  final String email;

  const VerifyLoginOtpPage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyLoginOtpPage> createState() => _VerifyLoginOtpPageState();
}

class _VerifyLoginOtpPageState extends State<VerifyLoginOtpPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int resendTimer = 0;
  Timer? _timer;
  bool canResend = true;
  bool _isInitializing = false;
  bool _showPermissionWall = false;

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startResendTimer() {
    setState(() {
      resendTimer = 60;
      canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (resendTimer > 0) {
            resendTimer--;
          } else {
            canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void resendCode() {
    if (canResend) {
      context.read<HelperAuthCubit>().resendLoginOtp(widget.email);
      startResendTimer();
    }
  }

  Future<void> _initLocationAndNavigate() async {
    setState(() => _isInitializing = true);

    try {
      final localDs = sl<HelperLocalDataSource>();
      final helper = await localDs.getCurrentHelper();
      final token = helper?.token;

      if (token != null) {
        final locCubit = sl<HelperLocationCubit>();
        final granted = await locCubit.requestPermissionAndInitialize(token);

        if (!granted) {
          if (mounted) setState(() { _isInitializing = false; _showPermissionWall = true; });
          return;
        }

        try {
          await sl<UpdateAvailabilityUseCase>()(HelperAvailabilityState.availableNow);
        } catch (_) {}
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isInitializing = false);
      context.go(AppRouter.helperHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    if (_showPermissionWall) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceXL),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_off_rounded, color: theme.colorScheme.error, size: 64),
                ),
                const SizedBox(height: AppTheme.space2XL),
                Text(
                  'Location Access Required',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Text(
                  'Toury needs your location to show you nearby travelers and send you booking requests.\n\nPlease enable location access in settings.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space2XL),
                CustomButton(
                  text: 'Open Settings',
                  onPressed: () => Geolocator.openAppSettings(),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                TextButton(
                  onPressed: () {
                    setState(() => _showPermissionWall = false);
                    _initLocationAndNavigate();
                  },
                  child: Text('Try Again', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await sl<UpdateAvailabilityUseCase>()(HelperAvailabilityState.offline);
                    } catch (_) {}
                    if (mounted) context.go(AppRouter.helperHome);
                  },
                  child: Text('Stay Offline', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTheme.spaceXL),
              Text(
                'Setting up your profile...',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go(AppRouter.helperLogin),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<HelperAuthCubit, HelperAuthState>(
        listener: (context, state) {
          if (state is HelperAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
            );
          } else if (state is HelperAuthAuthenticated) {
            _initLocationAndNavigate();
          } else if (state is HelperAuthResendSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.space2XL),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceXL),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space2XL),

                Text(
                  loc.translate("verify_email") ?? "Verification Code",
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  "Enter the 6-digit code sent to",
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space2XL),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: state is! HelperAuthLoading,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: "000000",
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                            letterSpacing: 12,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXL),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length != 6) return 'Must be 6 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space2XL),

                      CustomButton(
                        text: loc.translate("verify") ?? 'Verify & Login',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<HelperAuthCubit>().verifyLoginOtp(
                                  email: widget.email,
                                  code: _codeController.text.trim(),
                                );
                          }
                        },
                        isLoading: state is HelperAuthLoading,
                      ),
                      const SizedBox(height: AppTheme.spaceLG),

                      TextButton(
                        onPressed: (state is HelperAuthLoading || !canResend) ? null : resendCode,
                        child: Text(
                          canResend ? (loc.translate("resend_code") ?? "Resend Code") : 'Resend in ${resendTimer}s',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: (state is HelperAuthLoading || !canResend) ? theme.colorScheme.onSurface.withOpacity(0.4) : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
