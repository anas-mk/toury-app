// lib/core/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final TextStyle? hintStyle;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixWidget,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.hintStyle,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 💡 تحديد نمط رمادي افتراضي للـ hint text
    final defaultHintStyle = AppTheme.bodyLarge.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTheme.labelMedium.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXS),
        ],
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && _obscureText,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          style: AppTheme.bodyLarge.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            // 💡 استخدام النمط المخصص إذا وجد، أو النمط الرمادي الافتراضي
            hintStyle: widget.hintStyle ?? defaultHintStyle,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
              widget.prefixIcon,
              color: theme.iconTheme.color?.withOpacity(0.6),
            )
                : null,
            suffixIcon: _buildSuffixIcon(theme),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.isPassword) {
      return IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            key: ValueKey<bool>(_obscureText),
            color: theme.iconTheme.color?.withOpacity(0.6),
          ),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return widget.suffixWidget;
  }
}

// ============================================
// 🎯 Specialized Text Fields
// ============================================

class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const EmailTextField({
    super.key,
    this.controller,
    this.label,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomTextField(
      hintText: "Enter Your Email",
      label: label ?? 'Email',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
      textInputAction: TextInputAction.next,
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
      // ترك هذا الكود هنا يضمن لون رمادي (حتى لو تم إزالته سيبقى رمادي بسبب التعديل في CustomTextField)
      hintStyle: AppTheme.bodyLarge.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
}

class PasswordTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  const PasswordTextField({
    super.key,
    this.controller,
    this.label,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    // سيستخدم هذا الحقل اللون الرمادي الافتراضي للـ hint text الآن
    return CustomTextField(
      label: label ?? 'Password',
      controller: controller,
      isPassword: true,
      prefixIcon: Icons.lock_outline,
      textInputAction: textInputAction ?? TextInputAction.done,
      validator: validator ?? _defaultPasswordValidator,
      onChanged: onChanged,
    );
  }

  String? _defaultPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}

class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const PhoneTextField({
    super.key,
    this.controller,
    this.label,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label ?? 'Phone Number',
      controller: controller,
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone_outlined,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
      onChanged: onChanged,
    );
  }
}