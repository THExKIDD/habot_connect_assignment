import 'package:flutter/material.dart';

/// UI Byt — reusable labeled text field following Material 3 conventions.
///
/// Pure [StatelessWidget]: all mutable state (controller, focus node) is
/// owned by the screen composition layer and passed in as constructor params.
/// Zero business logic.
class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? prefixText;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.focusNode,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: readOnly
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
              ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: readOnly
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
