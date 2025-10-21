import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color? fillColor;
  final double borderRadius;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor,
    this.borderRadius = 12,
    this.validator,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _obscure : false,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: isDark ? Colors.grey.shade300 : Colors.grey)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: isDark ? Colors.grey.shade300 : Colors.grey,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : (widget.suffixIcon != null
            ? Icon(widget.suffixIcon, color: isDark ? Colors.grey.shade300 : Colors.grey)
            : null),
        filled: true,
        fillColor: widget.fillColor ??
            (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
