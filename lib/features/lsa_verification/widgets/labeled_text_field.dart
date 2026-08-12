import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// UI Byt — labeled text field with two distinct visual modes:
///
/// **Mutable** (default): clean Material 3 input with focused border highlight.
///
/// **System** ([isSystemField] = true): gradient-tinted, lock-badged field that
/// clearly communicates "hands-off — system assigned". Cannot be edited.
class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool isSystemField;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.focusNode,
    this.readOnly = false,
    this.isSystemField = false,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return isSystemField
        ? _SystemField(label: label, controller: controller, hint: hint)
        : _MutableField(
            label: label,
            controller: controller,
            hint: hint,
            focusNode: focusNode,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
          );
  }
}

// ─────────────────────────── MUTABLE FIELD ───────────────────────────────────

class _MutableField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _MutableField({
    required this.label,
    required this.controller,
    this.hint,
    this.focusNode,
    required this.readOnly,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(
          label: label,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: tt.bodyLarge?.copyWith(
            color: readOnly ? cs.onSurfaceVariant : cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tt.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: readOnly
                ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
                : cs.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── SYSTEM FIELD ────────────────────────────────────

class _SystemField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;

  const _SystemField({
    required this.label,
    required this.controller,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;

    // Gradient palette for the system field — amber/orange tones signal
    // "system territory" vs. the blue/teal used for interactive UI.
    final gradientColors = isDark
        ? [const Color(0xFF2A2010), const Color(0xFF1A1A10)]
        : [const Color(0xFFFFF8E1), const Color(0xFFFFF3CD)];

    final borderColor = isDark
        ? const Color(0xFF7A6020).withValues(alpha: 0.6)
        : const Color(0xFFFFCC02).withValues(alpha: 0.7);

    final accentColor = isDark ? const Color(0xFFFFC107) : const Color(0xFFF59E0B);
    final textColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFF92650A);
    final valueColor = isDark ? const Color(0xFFFFECB3) : const Color(0xFF5C4200);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row with SYSTEM badge
        Row(
          children: [
            _FieldLabel(label: label, color: textColor),
            const SizedBox(width: 8),
            _SystemBadge(accentColor: accentColor),
          ],
        ),
        const SizedBox(height: 8),

        // Gradient container wrapping the field
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              // Lock icon tab on the left
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.25),
                      accentColor.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                  border: Border(
                    right: BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Icon(Icons.lock_rounded, size: 16, color: accentColor),
              ),

              // Value text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Text(
                    controller.text.isNotEmpty
                        ? controller.text
                        : (hint ?? ''),
                    style: tt.bodyMedium?.copyWith(
                      color: controller.text.isNotEmpty
                          ? valueColor
                          : textColor.withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Caption
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'System-assigned · Read only · Cannot be modified',
            style: tt.labelSmall?.copyWith(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── SHARED ATOMS ────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _FieldLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _SystemBadge extends StatelessWidget {
  final Color accentColor;

  const _SystemBadge({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Text(
        'SYSTEM',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              fontSize: 9,
            ),
      ),
    );
  }
}
