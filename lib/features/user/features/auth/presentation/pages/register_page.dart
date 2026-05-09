import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 4;

  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedGender = 'Male';
  DateTime? _selectedBirthDate;
  String? _selectedCountry;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _phoneError;

  static const _bg = Color(0xFFF4F4FF);
  static const _primary = Color(0xFF1B237E);

  static const List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Argentina',
    'Armenia', 'Australia', 'Austria', 'Azerbaijan', 'Bahrain', 'Bangladesh',
    'Belarus', 'Belgium', 'Bolivia', 'Bosnia and Herzegovina', 'Brazil',
    'Bulgaria', 'Cambodia', 'Cameroon', 'Canada', 'Chile', 'China',
    'Colombia', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic', 'Denmark',
    'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador', 'Estonia',
    'Ethiopia', 'Finland', 'France', 'Georgia', 'Germany', 'Ghana', 'Greece',
    'Guatemala', 'Honduras', 'Hungary', 'Iceland', 'India', 'Indonesia',
    'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 'Jamaica', 'Japan',
    'Jordan', 'Kazakhstan', 'Kenya', 'Kuwait', 'Kyrgyzstan', 'Latvia',
    'Lebanon', 'Libya', 'Lithuania', 'Luxembourg', 'Malaysia', 'Maldives',
    'Malta', 'Mexico', 'Moldova', 'Monaco', 'Mongolia', 'Morocco',
    'Mozambique', 'Myanmar', 'Nepal', 'Netherlands', 'New Zealand',
    'Nicaragua', 'Nigeria', 'North Korea', 'Norway', 'Oman', 'Pakistan',
    'Palestine', 'Panama', 'Paraguay', 'Peru', 'Philippines', 'Poland',
    'Portugal', 'Qatar', 'Romania', 'Russia', 'Saudi Arabia', 'Senegal',
    'Serbia', 'Singapore', 'Slovakia', 'Slovenia', 'Somalia', 'South Africa',
    'South Korea', 'Spain', 'Sri Lanka', 'Sudan', 'Sweden', 'Switzerland',
    'Syria', 'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Tunisia',
    'Turkey', 'Turkmenistan', 'Uganda', 'Ukraine', 'United Arab Emirates',
    'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Venezuela',
    'Vietnam', 'Yemen', 'Zimbabwe',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validateCurrentStep() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _phoneError = null;
    });

    switch (_currentStep) {
      case 0:
        final name = _userNameController.text.trim();
        if (name.isEmpty) {
          setState(() => _nameError = 'Please enter your name');
          return false;
        }
        if (name.length < 2) {
          setState(() => _nameError = 'Name must be at least 2 characters');
          return false;
        }
        return true;

      case 1:
        final email = _emailController.text.trim();
        if (email.isEmpty) {
          setState(() => _emailError = 'Please enter your email');
          return false;
        }
        if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) {
          setState(() => _emailError = 'Please enter a valid email address');
          return false;
        }
        return true;

      case 2:
        final pass = _passwordController.text;
        final confirm = _confirmPasswordController.text;
        if (pass.isEmpty) {
          setState(() => _passwordError = 'Please enter a password');
          return false;
        }
        if (pass.length < 8) {
          setState(() => _passwordError = 'Password must be at least 8 characters');
          return false;
        }
        if (confirm != pass) {
          setState(() => _confirmError = "Passwords don't match");
          return false;
        }
        return true;

      case 3:
        if (_phoneController.text.trim().isEmpty) {
          setState(() => _phoneError = 'Please enter your phone number');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _submitForm() {
    if (_selectedBirthDate == null) {
      _showError('Please select your birth date');
      return;
    }
    if (_selectedCountry == null) {
      _showError('Please select your country');
      return;
    }

    context.read<AuthCubit>().register(
      email: _emailController.text.trim(),
      userName: _userNameController.text.trim(),
      password: _passwordController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gender: _selectedGender,
      birthDate: _selectedBirthDate!,
      country: _selectedCountry!,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showError(state.message);
          } else if (state is AuthRegistrationVerificationNeeded) {
            context.go(
              '${AppRouter.verifyCode}?email=${Uri.encodeComponent(state.email)}',
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful ✅')),
            );
            context.go(AppRouter.login);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _BackButton(onTap: _prevStep),
                  const SizedBox(height: 32),
                  _ProgressDots(current: _currentStep, total: _totalSteps),
                  const SizedBox(height: 32),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _NameStep(
                          controller: _userNameController,
                          error: _nameError,
                          onContinue: _nextStep,
                          onLogin: () => context.go(AppRouter.login),
                        ),
                        _EmailStep(
                          controller: _emailController,
                          error: _emailError,
                          onContinue: _nextStep,
                          onLogin: () => context.go(AppRouter.login),
                        ),
                        _PasswordStep(
                          passwordController: _passwordController,
                          confirmController: _confirmPasswordController,
                          obscurePassword: _obscurePassword,
                          obscureConfirm: _obscureConfirm,
                          passwordError: _passwordError,
                          confirmError: _confirmError,
                          onTogglePassword: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          onToggleConfirm: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          onContinue: _nextStep,
                          onLogin: () => context.go(AppRouter.login),
                        ),
                        _PersonalStep(
                          phoneController: _phoneController,
                          phoneError: _phoneError,
                          selectedGender: _selectedGender,
                          selectedBirthDate: _selectedBirthDate,
                          selectedCountry: _selectedCountry,
                          isLoading: state is AuthLoading,
                          onGenderChanged: (g) =>
                              setState(() => _selectedGender = g),
                          onPickDate: _pickDate,
                          onPickCountry: _showCountryPicker,
                          onContinue: _nextStep,
                          onLogin: () => context.go(AppRouter.login),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Pickers ─────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedBirthDate = picked);
  }

  void _showCountryPicker() {
    final searchCtrl = TextEditingController();
    List<String> filtered = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Country',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => setModal(
                    () => filtered = _countries
                        .where((c) => c.toLowerCase().contains(v.toLowerCase()))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final country = filtered[i];
                    final isSelected = country == _selectedCountry;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        country,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? _primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: _primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedCountry = country);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFF1B237E),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isDone = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isActive || isDone) ? const Color(0xFF1B237E) : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StepHeading extends StatelessWidget {
  final String text;
  const _StepHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A2E),
        height: 1.1,
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool showToggle;
  final VoidCallback? onToggle;
  final String? error;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _UnderlineField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.showToggle = false,
    this.onToggle,
    this.error,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: onToggle,
                  )
                : null,
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1B237E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;

  const _ContinueButton({
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B237E),
          disabledBackgroundColor: const Color(0xFF1B237E).withValues(alpha: 0.6),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            ' Login',
            style: TextStyle(
              color: Color(0xFF1B237E),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step pages ───────────────────────────────────────────────────────────────

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onContinue;
  final VoidCallback onLogin;

  const _NameStep({
    required this.controller,
    required this.error,
    required this.onContinue,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeading("What's your\nname?"),
        const SizedBox(height: 48),
        _UnderlineField(
          controller: controller,
          hint: 'First and last name',
          error: error,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 48),
        _ContinueButton(onPressed: onContinue),
        const Spacer(),
        _LoginLink(onTap: onLogin),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _EmailStep extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onContinue;
  final VoidCallback onLogin;

  const _EmailStep({
    required this.controller,
    required this.error,
    required this.onContinue,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeading("What's your\nemail?"),
        const SizedBox(height: 48),
        _UnderlineField(
          controller: controller,
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
          error: error,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 48),
        _ContinueButton(onPressed: onContinue),
        const Spacer(),
        _LoginLink(onTap: onLogin),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final String? passwordError;
  final String? confirmError;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onContinue;
  final VoidCallback onLogin;

  const _PasswordStep({
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.passwordError,
    required this.confirmError,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onContinue,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepHeading("Create a\npassword"),
        const SizedBox(height: 48),
        _UnderlineField(
          controller: passwordController,
          hint: 'Password (min. 8 characters)',
          obscure: obscurePassword,
          showToggle: true,
          onToggle: onTogglePassword,
          error: passwordError,
        ),
        const SizedBox(height: 24),
        _UnderlineField(
          controller: confirmController,
          hint: 'Confirm password',
          obscure: obscureConfirm,
          showToggle: true,
          onToggle: onToggleConfirm,
          error: confirmError,
        ),
        const SizedBox(height: 48),
        _ContinueButton(onPressed: onContinue),
        const Spacer(),
        _LoginLink(onTap: onLogin),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PersonalStep extends StatelessWidget {
  final TextEditingController phoneController;
  final String? phoneError;
  final String selectedGender;
  final DateTime? selectedBirthDate;
  final String? selectedCountry;
  final bool isLoading;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickCountry;
  final VoidCallback onContinue;
  final VoidCallback onLogin;

  const _PersonalStep({
    required this.phoneController,
    required this.phoneError,
    required this.selectedGender,
    required this.selectedBirthDate,
    required this.selectedCountry,
    required this.isLoading,
    required this.onGenderChanged,
    required this.onPickDate,
    required this.onPickCountry,
    required this.onContinue,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeading("Almost\ndone!"),
          const SizedBox(height: 32),
          _UnderlineField(
            controller: phoneController,
            hint: 'Phone number',
            keyboardType: TextInputType.phone,
            error: phoneError,
          ),
          const SizedBox(height: 28),
          _GenderSelector(
            selected: selectedGender,
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 28),
          _DateTile(
            date: selectedBirthDate,
            onTap: onPickDate,
          ),
          const SizedBox(height: 28),
          _CountryTile(
            country: selectedCountry,
            onTap: onPickCountry,
          ),
          const SizedBox(height: 40),
          _ContinueButton(
            onPressed: onContinue,
            isLoading: isLoading,
            label: 'Create Account',
          ),
          const SizedBox(height: 16),
          _LoginLink(onTap: onLogin),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _GenderSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                value: 'Male',
                icon: Icons.male_rounded,
                isSelected: selected == 'Male',
                onTap: () => onChanged('Male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderOption(
                value: 'Female',
                icon: Icons.female_rounded,
                isSelected: selected == 'Female',
                onTap: () => onChanged('Female'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B237E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B237E) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[500],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateTile({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Birth date',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasValue
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Select your birthday',
                  style: TextStyle(
                    fontSize: 16,
                    color: hasValue ? const Color(0xFF1A1A2E) : Colors.grey[400],
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey[400],
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(
            color: Color(0xFFCCCCCC),
            height: 1,
            thickness: 1.5,
          ),
        ],
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  final String? country;
  final VoidCallback onTap;

  const _CountryTile({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = country != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Country',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? country! : 'Select your country',
                  style: TextStyle(
                    fontSize: 16,
                    color: hasValue ? const Color(0xFF1A1A2E) : Colors.grey[400],
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[400],
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(
            color: Color(0xFFCCCCCC),
            height: 1,
            thickness: 1.5,
          ),
        ],
      ),
    );
  }
}
