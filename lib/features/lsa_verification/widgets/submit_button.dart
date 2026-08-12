import 'package:flutter/material.dart';
import '../models/compliance_state.dart';

/// UI Byt — the "Verify & Submit" action button.
///
/// Pure [StatelessWidget]: button enabled/disabled state is derived from
/// [currentState] passed in. No business logic — just maps state → enabled.
/// [onPressed] callback is owned by the screen composition layer.
class SubmitButton extends StatelessWidget {
  final ComplianceState currentState;
  final VoidCallback onPressed;

  const SubmitButton({
    super.key,
    required this.currentState,
    required this.onPressed,
  });

  /// Button is active only when idle — locks during processing and after quarantine/success.
  bool get _isEnabled => currentState is ComplianceIdle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _isEnabled ? onPressed : null,
        icon: Icon(
          _isEnabled ? Icons.send_rounded : Icons.lock_outline_rounded,
          size: 20,
        ),
        label: Text(
          'Verify & Submit',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor:
              _isEnabled ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          foregroundColor:
              _isEnabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
