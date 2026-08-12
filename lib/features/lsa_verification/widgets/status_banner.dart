import 'package:flutter/material.dart';
import '../models/compliance_state.dart';

/// UI Byt — color-coded status banner reflecting the 4 compliance states.
///
/// Pure [StatelessWidget]: receives the current [ComplianceState] as a param.
/// No state reads, no business logic — just maps state → visual.
class StatusBanner extends StatelessWidget {
  final ComplianceState state;

  const StatusBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(state, Theme.of(context).colorScheme);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _BannerTile(
        key: ValueKey(state.runtimeType),
        icon: config.icon,
        label: config.label,
        backgroundColor: config.backgroundColor,
        foregroundColor: config.foregroundColor,
        isLoading: state is ComplianceProcessing,
      ),
    );
  }

  _BannerConfig _configFor(ComplianceState state, ColorScheme cs) {
    return switch (state) {
      ComplianceIdle() => _BannerConfig(
          icon: Icons.radio_button_unchecked_rounded,
          label: 'Idle — Ready for submission',
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: cs.onSurfaceVariant,
        ),
      ComplianceProcessing() => _BannerConfig(
          icon: Icons.sync_rounded,
          label: 'Processing — Verifying compliance…',
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
        ),
      ComplianceQuarantined(:final reason) => _BannerConfig(
          icon: Icons.lock_rounded,
          label: reason,
          backgroundColor: cs.errorContainer,
          foregroundColor: cs.onErrorContainer,
        ),
      ComplianceSuccess(:final traceId) => _BannerConfig(
          icon: Icons.verified_rounded,
          label: 'Success — Trace ID: $traceId',
          backgroundColor: const Color(0xFF1B5E20).withValues(alpha: 0.12),
          foregroundColor: const Color(0xFF1B5E20),
        ),
    };
  }
}

class _BannerConfig {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _BannerConfig({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class _BannerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;

  const _BannerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: foregroundColor,
              ),
            )
          else
            Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
