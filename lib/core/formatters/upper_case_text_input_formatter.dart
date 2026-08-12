import 'package:flutter/services.dart';

/// Text input formatter that forces all entered characters to uppercase.
///
/// Preserves cursor position and selection so the user experience stays smooth.
/// Apply this to any field that must only accept capital letters per the
/// HabotConnect data standard (e.g. parent_consent_code).
class UpperCaseTextInputFormatter extends TextInputFormatter {
  const UpperCaseTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final uppercased = newValue.text.toUpperCase();

    // Only rebuild the value if something actually changed to avoid
    // triggering unnecessary rebuilds.
    if (uppercased == newValue.text) return newValue;

    return newValue.copyWith(
      text: uppercased,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
