import 'package:flutter/material.dart';
import 'package:habot_connect_assignment/features/lsa_verification/logic/compliance_cubit/compliance_state.dart';

/// UI Byt — visually rich status banner with gradient backgrounds,
/// animated pulse for Processing, and distinct iconography per state.
class StatusBanner extends StatelessWidget {
  final ComplianceState state;

  const StatusBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: switch (state) {
        ComplianceIdle() => _IdleBanner(key: const ValueKey('idle')),
        ComplianceProcessing() =>
          _ProcessingBanner(key: const ValueKey('processing')),
        ComplianceQuarantined(:final reason) =>
          _QuarantinedBanner(key: const ValueKey('quarantined'), reason: reason),
        ComplianceSuccess() =>
          const _SuccessBanner(key: ValueKey('success')),
      },
    );
  }
}

// ─────────────────────────── IDLE ────────────────────────────────────────────

class _IdleBanner extends StatelessWidget {
  const _IdleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF37474F).withValues(alpha: 0.08),
          const Color(0xFF546E7A).withValues(alpha: 0.04),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: const Color(0xFF90A4AE).withValues(alpha: 0.4),
      icon: const _StatusDot(color: Color(0xFF78909C)),
      label: 'System Idle',
      sublabel: 'Ready for LSA onboarding verification',
      labelColor: const Color(0xFF546E7A),
      sublabelColor: const Color(0xFF90A4AE),
    );
  }
}

// ─────────────────────────── PROCESSING ──────────────────────────────────────

class _ProcessingBanner extends StatefulWidget {
  const _ProcessingBanner({super.key});

  @override
  State<_ProcessingBanner> createState() => _ProcessingBannerState();
}

class _ProcessingBannerState extends State<_ProcessingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return _BannerShell(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1565C0).withValues(alpha: 0.12 * _glow.value + 0.06),
              const Color(0xFF0288D1).withValues(alpha: 0.06 * _glow.value + 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: const Color(0xFF42A5F5).withValues(alpha: _glow.value * 0.7),
          icon: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(
                    const Color(0xFF42A5F5), const Color(0xFF1565C0), _glow.value)!,
              ),
            ),
          ),
          label: 'Verifying Compliance…',
          sublabel: 'Transmitting onboarding payload to compliance gate',
          labelColor: const Color(0xFF1565C0),
          sublabelColor: const Color(0xFF42A5F5),
        );
      },
    );
  }
}

// ─────────────────────────── QUARANTINED ─────────────────────────────────────

class _QuarantinedBanner extends StatelessWidget {
  final String reason;
  const _QuarantinedBanner({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      gradient: const LinearGradient(
        colors: [Color(0x1FC62828), Color(0x0DB71C1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: const Color(0xFFEF5350).withValues(alpha: 0.5),
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
      ),
      label: 'DATA QUARANTINED',
      sublabel: reason,
      labelColor: const Color(0xFFC62828),
      sublabelColor: const Color(0xFFE57373),
      isError: true,
    );
  }
}

// ─────────────────────────── SUCCESS ─────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      gradient: const LinearGradient(
        colors: [Color(0x1F1B5E20), Color(0x0D2E7D32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: const Color(0xFF43A047).withValues(alpha: 0.5),
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.45),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
      ),
      label: 'VERIFICATION APPROVED',
      sublabel: 'LSA onboarding data compliance verified',
      labelColor: const Color(0xFF1B5E20),
      sublabelColor: const Color(0xFF388E3C),
    );
  }
}

// ─────────────────────────── SHARED SHELL ────────────────────────────────────

class _BannerShell extends StatelessWidget {
  final Gradient gradient;
  final Color borderColor;
  final Widget icon;
  final String label;
  final String sublabel;
  final Color labelColor;
  final Color sublabelColor;
  final bool isError;

  const _BannerShell({
    required this.gradient,
    required this.borderColor,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.labelColor,
    required this.sublabelColor,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: icon,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),
                if (sublabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sublabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: sublabelColor,
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── STATUS DOT ──────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
