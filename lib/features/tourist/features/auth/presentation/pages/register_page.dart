import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey1 = GlobalKey<FormState>(); // Tab 1 - Account Info
  final _formKey2 = GlobalKey<FormState>(); // Tab 2 - Personal Info

  final emailController = TextEditingController();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneNumberController = TextEditingController();

  String selectedGender = 'Male';
  DateTime? selectedBirthDate;
  String? selectedCountry;

  late TabController _tabController;

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    emailController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  void _goToNextTab() {
    if (_formKey1.currentState!.validate()) {
      _tabController.animateTo(1);
    }
  }

  void _goToPreviousTab() {
    _tabController.animateTo(0);
  }

  void _submitForm(BuildContext context, AuthState state, AppLocalizations loc) {
    if (!_formKey2.currentState!.validate()) return;

    if (selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.translate("select_birth_date") ?? 'Please select your birth date',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (selectedCountry == null || selectedCountry!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.translate("select_country") ?? 'Please select your country',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<AuthCubit>().register(
      email: emailController.text.trim(),
      userName: userNameController.text.trim(),
      password: passwordController.text.trim(),
      phoneNumber: phoneNumberController.text.trim(),
      gender: selectedGender,
      birthDate: selectedBirthDate!,
      country: selectedCountry!,
    );
  }

  void _showCountryPicker(bool isDark, AppLocalizations loc) {
    final searchController = TextEditingController();
    List<String> filteredCountries = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.translate("select_country") ?? 'Select Country',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: loc.translate("search_country") ?? 'Search...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: AppColor.primaryColor),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                          onPressed: () {
                            searchController.clear();
                            setModalState(() => filteredCountries = List.from(_countries));
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColor.primaryColor, width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filteredCountries = _countries
                              .where((c) => c.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredCountries.isEmpty
                        ? Center(
                      child: Text(
                        loc.translate("no_results") ?? 'No results found',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        final isSelected = country == selectedCountry;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          title: Text(
                            country,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColor.primaryColor)
                              : null,
                          tileColor: isSelected
                              ? AppColor.primaryColor.withOpacity(0.1)
                              : null,
                          onTap: () {
                            setState(() => selectedCountry = country);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E0E)
          : AppColor.primaryColor.withOpacity(0.95),
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
              );
            } else if (state is AuthRegistrationVerificationNeeded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.blue),
              );
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  context.go('${AppRouter.verifyCode}?email=${Uri.encodeComponent(state.email)}');
                }
              });
            } else if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate("register_success") ?? "Registration successful ✅"),
                ),
              );
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) context.go(AppRouter.login);
              });
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Title ──
                    Text(
                      loc.translate("register") ?? "Register",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate("register_subtitle") ?? "Create your account to get started",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),

                    // ── Card ──
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark
                            ? []
                            : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Tab Bar (Modern Icon-Only Pill Style) ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                            child: AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, _) {
                                return Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[850] : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: List.generate(2, (index) {
                                      final isSelected = _tabController.index == index;
                                      final icons = [Icons.lock_outline, Icons.person_outline];
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (index == 1) {
                                              _goToNextTab();
                                            } else {
                                              _goToPreviousTab();
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeInOut,
                                            margin: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColor.primaryColor
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: isSelected
                                                  ? [
                                                BoxShadow(
                                                  color: AppColor.primaryColor.withOpacity(0.35),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                )
                                              ]
                                                  : [],
                                            ),
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 250),
                                                    child: Icon(
                                                      icons[index],
                                                      size: 20,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : (isDark ? Colors.white38 : Colors.grey),
                                                    ),
                                                  ),

                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),

                          // ── Tab Views ──
                          SizedBox(
                            height: 430,
                            child: TabBarView(
                              controller: _tabController,
                              // ✅ منع السحب اليدوي - لازم يعدي Tab 1 validation الأول
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                // ── Tab 1: Account Info ──
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                  child: Form(
                                    key: _formKey1,
                                    child: Column(
                                      children: [
                                        CustomTextField(
                                          hintText: loc.translate("email") ?? "Email",
                                          controller: emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          prefixIcon: Icons.email_outlined,
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return loc.translate("field_required") ??
                                                  'This field is required';
                                            }
                                            if (!v.contains('@')) {
                                              return loc.translate("invalid_email") ??
                                                  'Enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        CustomTextField(
                                          hintText: loc.translate("name") ?? "Username",
                                          controller: userNameController,
                                          prefixIcon: Icons.person_outline,
                                          validator: (v) => v == null || v.isEmpty
                                              ? loc.translate("field_required") ??
                                              'This field is required'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        CustomTextField(
                                          hintText: loc.translate("password") ?? "Password",
                                          controller: passwordController,
                                          isPassword: true,
                                          prefixIcon: Icons.lock_outline,
                                          validator: (v) => v == null || v.isEmpty
                                              ? loc.translate("field_required") ??
                                              'This field is required'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        CustomTextField(
                                          hintText: loc.translate("confirm_password") ??
                                              "Confirm Password",
                                          controller: confirmPasswordController,
                                          isPassword: true,
                                          prefixIcon: Icons.lock_outline,
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return loc.translate("field_required") ??
                                                  'This field is required';
                                            }
                                            if (v != passwordController.text) {
                                              return loc.translate("passwords_dont_match") ??
                                                  'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                        const Spacer(),
                                        // ── Next Button ──
                                        ElevatedButton(
                                          onPressed: _goToNextTab,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColor.primaryColor,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(double.infinity, 50),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                loc.translate("next") ?? 'Next',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Tab 2: Personal Info ──
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                  child: Form(
                                    key: _formKey2,
                                    child: Column(
                                      children: [
                                        CustomTextField(
                                          hintText: loc.translate("phone_number") ?? "Phone Number",
                                          controller: phoneNumberController,
                                          keyboardType: TextInputType.phone,
                                          prefixIcon: Icons.phone_outlined,
                                          validator: (v) => v == null || v.isEmpty
                                              ? loc.translate("field_required") ??
                                              'This field is required'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        _buildGenderField(isDark, loc),
                                        const SizedBox(height: 14),
                                        _buildBirthDateField(isDark, loc),
                                        const SizedBox(height: 14),
                                        _buildCountryField(isDark, loc),
                                        const Spacer(),
                                        // ── Back + Register Buttons ──
                                        Row(
                                          children: [
                                            // Back button
                                            OutlinedButton(
                                              onPressed: _goToPreviousTab,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColor.primaryColor,
                                                side: const BorderSide(
                                                    color: AppColor.primaryColor),
                                                minimumSize: const Size(50, 50),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: const Icon(Icons.arrow_back_rounded),
                                            ),
                                            const SizedBox(width: 12),
                                            // Register button
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: state is AuthLoading
                                                    ? null
                                                    : () => _submitForm(context, state, loc),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColor.primaryColor,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: const Size(double.infinity, 50),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                ),
                                                child: state is AuthLoading
                                                    ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                                    : Text(
                                                  loc.translate("register_button") ??
                                                      'Register',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Login Link ──
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  loc.translate("already_have_account") ??
                                      "Already have an account?",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go(AppRouter.login),
                                  child: Text(
                                    loc.translate("login") ?? "Login",
                                    style: const TextStyle(
                                      color: AppColor.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildCountryField(bool isDark, AppLocalizations loc) {
    return InkWell(
      onTap: () => _showCountryPicker(isDark, loc),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: loc.translate("country") ?? 'Country',
          prefixIcon: Icon(
            Icons.location_on_outlined,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: selectedCountry == null
                  ? Colors.grey.shade300
                  : AppColor.primaryColor,
              width: selectedCountry == null ? 1 : 1.5,
            ),
          ),
        ),
        child: Text(
          selectedCountry ?? (loc.translate("select_country") ?? 'Select Country'),
          style: TextStyle(
            color: selectedCountry != null
                ? (isDark ? Colors.white : Colors.black87)
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField(bool isDark, AppLocalizations loc) {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: InputDecoration(
        labelText: loc.translate("gender") ?? 'Gender',
        prefixIcon: Icon(
          Icons.person_2_outlined,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dropdownColor: isDark ? Colors.grey[900] : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      items: [
        DropdownMenuItem(value: 'Male', child: Text(loc.translate("male") ?? "Male")),
        DropdownMenuItem(value: 'Female', child: Text(loc.translate("female") ?? "Female")),
      ],
      onChanged: (val) => setState(() => selectedGender = val ?? 'Male'),
      validator: (v) => v == null
          ? loc.translate("field_required") ?? 'This field is required'
          : null,
    );
  }

  Widget _buildBirthDateField(bool isDark, AppLocalizations loc) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedBirthDate ??
              DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => selectedBirthDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: loc.translate("birth_date") ?? 'Birth Date',
          prefixIcon: Icon(
            Icons.calendar_month_rounded,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          selectedBirthDate != null
              ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
              : loc.translate("select_birth_date") ?? 'Select your birth date',
          style: TextStyle(
            color: selectedBirthDate != null
                ? (isDark ? Colors.white : Colors.black87)
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}