import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
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
      setState(() {
        if (resendTimer > 0) {
          resendTimer--;
        } else {
          canResend = true;
          timer.cancel();
        }
      });
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

        // Set helper availability to Online
        try {
          await sl<UpdateAvailabilityUseCase>()(HelperAvailabilityState.availableNow);
        } catch (_) { /* non-fatal */ }
      }
    } catch (_) { /* proceed to navigate even if location init fails */ }

    if (mounted) {
      setState(() => _isInitializing = false);
      context.go(AppRouter.helperHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    // ── Permission denied wall ─────────────────────────────────────────────────
    if (_showPermissionWall) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_rounded, color: Colors.redAccent, size: 64),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Location Access Required',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toury needs your location to show you nearby travelers and send you booking requests.\n\nPlease enable location access in your device settings.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Geolocator.openAppSettings(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() => _showPermissionWall = false);
                      _initLocationAndNavigate();
                    },
                    child: const Text('Try Again', style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await sl<UpdateAvailabilityUseCase>()(HelperAvailabilityState.offline);
                      } catch (_) {}
                      if (mounted) context.go(AppRouter.helperHome);
                    },
                    child: const Text('Stay Offline', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Initializing overlay ──────────────────────────────────────────────────
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColor.primaryColor),
              const SizedBox(height: 20),
              Text(
                'Setting up your profile…',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E0E)
          : AppColor.primaryColor.withValues(alpha: 0.95),
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: BlocConsumer<HelperAuthCubit, HelperAuthState>(
          listener: (context, state) {
            if (state is HelperAuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
              );
            } else if (state is HelperAuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login successful!'), backgroundColor: Colors.green),
              );
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
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined, size: 80, color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      loc.translate("verify_email") ?? "Verify Your Email",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate("verify_email_subtitle") ?? "We've sent a verification code to",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark
                            ? []
                            : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 6))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              enabled: state is! HelperAuthLoading,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: "000000",
                                hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 8),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return loc.translate("field_required") ?? 'This field is required';
                                }
                                if (v.length != 6) {
                                  return loc.translate("code_must_be_6_digits") ?? 'Code must be 6 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: state is HelperAuthLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<HelperAuthCubit>().verifyLoginOtp(
                                          email: widget.email,
                                          code: _codeController.text.trim(),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: state is HelperAuthLoading
                                  ? const SizedBox(
                                      height: 24, width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(loc.translate("verify") ?? 'Verify',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: (state is HelperAuthLoading || !canResend) ? null : resendCode,
                              child: Text(
                                canResend
                                    ? (loc.translate("resend_code") ?? "Resend Code")
                                    : 'Resend in ${resendTimer}s',
                                style: TextStyle(
                                  color: (state is HelperAuthLoading || !canResend) ? Colors.grey : AppColor.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.go(AppRouter.helperHome),
                      child: Text(
                        loc.translate("back_to_login") ?? "Back to Login",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
