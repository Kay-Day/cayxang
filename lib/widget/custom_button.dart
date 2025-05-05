import 'package:flutter/material.dart';
import '../services/config/themes.dart';

enum ButtonType { solid, outline }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonType type;
  final bool isDisabled;  // Thêm tham số này

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.type = ButtonType.solid,
    this.isDisabled = false,  // Thêm giá trị mặc định
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = type == ButtonType.solid
      ? ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey : AppColors.primary,
          disabledBackgroundColor: Colors.grey.shade300,
        )
      : OutlinedButton.styleFrom(
          foregroundColor: isDisabled ? Colors.grey : AppColors.primary,
          side: BorderSide(
            color: isDisabled ? Colors.grey : AppColors.primary,
          ),
        );

    final button = icon != null
      ? (type == ButtonType.solid
          ? ElevatedButton.icon(
              onPressed: isDisabled ? null : onPressed,
              style: buttonStyle,
              icon: Icon(icon),
              label: Text(text),
            )
          : OutlinedButton.icon(
              onPressed: isDisabled ? null : onPressed,
              style: buttonStyle,
              icon: Icon(icon),
              label: Text(text),
            ))
      : (type == ButtonType.solid
          ? ElevatedButton(
              onPressed: isDisabled ? null : onPressed,
              style: buttonStyle,
              child: Text(text),
            )
          : OutlinedButton(
              onPressed: isDisabled ? null : onPressed,
              style: buttonStyle,
              child: Text(text),
            ));

    if (isLoading) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: null,
          style: buttonStyle,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: button,
    );
  }
}