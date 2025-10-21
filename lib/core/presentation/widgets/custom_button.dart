import 'package:flutter/material.dart';


class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final double? width;
  final double? height;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? icon;
  final Color? iconColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.width,
    this.height = 50,
    this.borderRadius = 12,
    this.textStyle,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 3,
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: textStyle ??
                  TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}




// class CustomButton extends StatelessWidget {
//   final String text;
//   final VoidCallback? onPressed;
//   final bool isLoading;
//   final Color? color;
//   final double? width;
//   final double? height;
//   final double borderRadius;
//   final TextStyle? textStyle;
//   final IconData? icon;
//   final Color? iconColor;
//
//   const CustomButton({
//     super.key,
//     required this.text,
//     required this.onPressed,
//     this.isLoading = false,
//     this.color,
//     this.width,
//     this.height = 50,
//     this.borderRadius = 12,
//     this.textStyle,
//     this.icon,
//     this.iconColor,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: width ?? double.infinity,
//       height: height,
//       child: ElevatedButton(
//         onPressed: isLoading ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color ?? AppColor.lightPrimary,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(borderRadius),
//           ),
//           elevation: 3,
//         ),
//         child: isLoading
//             ? const SizedBox(
//           width: 24,
//           height: 24,
//           child: CircularProgressIndicator(
//             color: Colors.white,
//             strokeWidth: 2,
//           ),
//         )
//             : Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (icon != null) ...[
//               Icon(icon, color: iconColor ?? Colors.white),
//               const SizedBox(width: 8),
//             ],
//             Text(
//               text,
//               style: textStyle ??
//                   const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
