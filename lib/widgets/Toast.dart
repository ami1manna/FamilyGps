import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart'; // Adjust the import based on your actual package path

// Enum for Toast Types
enum ToastType { success, error }

// Reusable Toast Component
class Toast {
  // Static method to show the toast
  static void show(BuildContext context, String message, ToastType type) {
    // Determine the toast parameters based on the type
    ToastificationType toastType;
    Color primaryColor;
    Color foregroundColor;

    if (type == ToastType.success) {
      toastType = ToastificationType.success;
      primaryColor = Colors.green; // Change to your desired success color
      foregroundColor = const Color(0xFFA011F2);
    } else {
      toastType = ToastificationType.error;
      primaryColor = Colors.red; // Change to your desired error color
      foregroundColor = const Color(0xFFA011F2);
    }

    toastification.show(
      context: context,
      type: toastType,
      style: ToastificationStyle.flat,
      title: Text(message, style: TextStyle(color: foregroundColor)),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (
        context,
        animation,
        alignment,
        child,
      ) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      primaryColor: primaryColor,
      foregroundColor: foregroundColor,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        const BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
      showProgressBar: true,
      dragToClose: true,
    );
  }
}