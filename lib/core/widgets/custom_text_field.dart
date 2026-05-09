// lib/core/widgets/custom_text_field.dart
//
// Themed text field primitive. The original API
// (`CustomTextField`, `EmailTextField`, `PasswordTextField`,
// `PhoneTextField`) is preserved — only the internals are modernized
// to use unified theme tokens for proper dark mode contrast.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

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

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
          style: theme.textTheme.bodyLarge?.copyWith(
            color: palette.textPrimary,
          ),
          cursorColor: palette.primary,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: widget.hintStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: AppSize.iconMd,
                    color: palette.textSecondary,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(palette),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(AppColors palette) {
    if (widget.isPassword) {
      return IconButton(
        splashRadius: 20,
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: palette.textSecondary,
          size: AppSize.iconMd,
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

class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const EmailTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label ?? 'Email',
      hintText: hintText ?? 'Enter your email',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
      textInputAction: TextInputAction.next,
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
      enabled: enabled,
    );
  }

  String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
}

class PasswordTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool enabled;

  const PasswordTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label ?? 'Password',
      hintText: hintText ?? 'Enter your password',
      controller: controller,
      isPassword: true,
      prefixIcon: Icons.lock_outline_rounded,
      textInputAction: textInputAction ?? TextInputAction.done,
      validator: validator ?? _defaultPasswordValidator,
      onChanged: onChanged,
      enabled: enabled,
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
  final String? hintText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const PhoneTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label ?? 'Phone Number',
      hintText: hintText ?? 'Enter phone number',
      controller: controller,
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone_outlined,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}
