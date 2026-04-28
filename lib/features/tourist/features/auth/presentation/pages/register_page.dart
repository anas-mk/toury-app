import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
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
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

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
    _tabController.addListener(() => setState(() {}));
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
      _showError(context, loc.translate("select_birth_date") ?? 'Please select your birth date');
      return;
    }

    if (selectedCountry == null || selectedCountry!.isEmpty) {
      _showError(context, loc.translate("select_country") ?? 'Please select your country');
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

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showCountryPicker(bool isDark, AppLocalizations loc) {
    final searchController = TextEditingController();
    List<String> filteredCountries = List.from(_countries);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radius2XL)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.spaceSM),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  Text(
                    loc.translate("select_country") ?? 'Select Country',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                    child: TextField(
                      controller: searchController,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: loc.translate("search_country") ?? 'Search country...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() => filteredCountries = List.from(_countries));
                                },
                              )
                            : null,
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
                  const SizedBox(height: AppTheme.spaceSM),
                  Expanded(
                    child: filteredCountries.isEmpty
                        ? Center(
                            child: Text(
                              loc.translate("no_results") ?? 'No results found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM),
                            itemCount: filteredCountries.length,
                            itemBuilder: (context, index) {
                              final country = filteredCountries[index];
                              final isSelected = country == selectedCountry;
                              return ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                                title: Text(
                                  country,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? theme.colorScheme.primary : null,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
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
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate("register") ?? "Create Account"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showError(context, state.message);
          } else if (state is AuthRegistrationVerificationNeeded) {
            context.go('${AppRouter.verifyCode}?email=${Uri.encodeComponent(state.email)}');
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.translate("register_success") ?? "Registration successful ✅")),
            );
            context.go(AppRouter.login);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepsIndicator(theme),
                const SizedBox(height: AppTheme.spaceXL),
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return IndexedStack(
                      index: _tabController.index,
                      children: [
                        _buildAccountInfoForm(loc, theme),
                        _buildPersonalInfoForm(loc, theme, state),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spaceXL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.translate("already_have_account") ?? "Already have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRouter.login),
                      child: Text(
                        loc.translate("login") ?? "Login",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepsIndicator(ThemeData theme) {
    return Row(
      children: [
        _buildStepItem(0, "Account", theme),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM),
            color: _tabController.index >= 1 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        _buildStepItem(1, "Personal", theme),
      ],
    );
  }

  Widget _buildStepItem(int index, String label, ThemeData theme) {
    final isActive = _tabController.index >= index;
    final isCurrent = _tabController.index == index;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          child: Center(
            child: isActive 
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text("${index + 1}", style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  )),
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoForm(AppLocalizations loc, ThemeData theme) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: loc.translate("email") ?? "Email",
            controller: emailController,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          CustomTextField(
            label: loc.translate("name") ?? "Username",
            controller: userNameController,
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          CustomTextField(
            label: loc.translate("password") ?? "Password",
            controller: passwordController,
            isPassword: true,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          CustomTextField(
            label: loc.translate("confirm_password") ?? "Confirm Password",
            controller: confirmPasswordController,
            isPassword: true,
          ),
          const SizedBox(height: AppTheme.space2XL),
          CustomButton(
            text: loc.translate("next") ?? 'Continue',
            onPressed: _goToNextTab,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoForm(AppLocalizations loc, ThemeData theme, AuthState state) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: loc.translate("phone_number") ?? "Phone Number",
            controller: phoneNumberController,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          _buildGenderSelector(loc, theme),
          const SizedBox(height: AppTheme.spaceLG),
          _buildBirthDatePicker(loc, theme),
          const SizedBox(height: AppTheme.spaceLG),
          _buildCountrySelector(loc, theme),
          const SizedBox(height: AppTheme.space2XL),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomButton(
                  text: "",
                  variant: ButtonVariant.outlined,
                  icon: Icons.arrow_back_rounded,
                  onPressed: _goToPreviousTab,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                flex: 3,
                child: CustomButton(
                  text: loc.translate("register_button") ?? 'Create Account',
                  onPressed: () => _submitForm(context, state, loc),
                  isLoading: state is AuthLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector(AppLocalizations loc, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate("gender") ?? "Gender",
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption("Male", Icons.male_rounded, theme),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: _buildGenderOption("Female", Icons.female_rounded, theme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, IconData icon, ThemeData theme) {
    final isSelected = selectedGender == value;
    return InkWell(
      onTap: () => setState(() => selectedGender = value),
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: AppTheme.spaceSM),
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthDatePicker(AppLocalizations loc, ThemeData theme) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => selectedBirthDate = picked);
      },
      child: CustomTextField(
        label: loc.translate("birth_date") ?? "Birth Date",
        hintText: selectedBirthDate != null
            ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
            : "Select your birthday",
        enabled: false,
        prefixIcon: Icons.calendar_today_rounded,
        controller: TextEditingController(
          text: selectedBirthDate != null 
              ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}' 
              : ""
        ),
      ),
    );
  }

  Widget _buildCountrySelector(AppLocalizations loc, ThemeData theme) {
    return InkWell(
      onTap: () => _showCountryPicker(theme.brightness == Brightness.dark, loc),
      child: CustomTextField(
        label: loc.translate("country") ?? "Country",
        hintText: selectedCountry ?? "Select your country",
        enabled: false,
        prefixIcon: Icons.public_rounded,
        controller: TextEditingController(text: selectedCountry ?? ""),
      ),
    );
  }
}
