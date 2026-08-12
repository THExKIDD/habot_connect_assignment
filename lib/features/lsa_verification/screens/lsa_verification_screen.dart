import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habot_connect_assignment/features/lsa_verification/logic/compliance_cubit/compliance_state.dart';

import '../../../../core/formatters/upper_case_text_input_formatter.dart';
import '../../../../core/logging/friction_logger.dart';
import '../logic/compliance_cubit/compliance_cubit.dart';
import '../widgets/header.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/status_banner.dart';
import '../widgets/submit_button.dart';

/// Composition-only screen layer — wires UI Byts to [ComplianceCubit].
class LsaVerificationScreen extends StatefulWidget {
  const LsaVerificationScreen({super.key});

  @override
  State<LsaVerificationScreen> createState() => _LsaVerificationScreenState();
}

class _LsaVerificationScreenState extends State<LsaVerificationScreen> {
  static const String _kPredecessorId = 'PRED-9982-XYZ';

  final TextEditingController _lsaIdController =
      TextEditingController(text: 'LSA-7049');
  final TextEditingController _consentController = TextEditingController();
  final TextEditingController _predecessorController =
      TextEditingController(text: _kPredecessorId);

  final FocusNode _consentFocusNode = FocusNode();

  Timer? _frictionTimer;
  DateTime? _focusStartTime;
  static const Duration _frictionThreshold = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _consentFocusNode.addListener(_onConsentFocusChanged);
    _consentController.addListener(_onConsentTextChanged);
  }

  void _onConsentFocusChanged() {
    if (_consentFocusNode.hasFocus) {
      _focusStartTime = DateTime.now();
      _startFrictionTimer();
    } else {
      _cancelFrictionTimer();
    }
  }

  void _onConsentTextChanged() {
    if (_consentFocusNode.hasFocus) {
      _cancelFrictionTimer();
      _startFrictionTimer();
    }
  }

  void _startFrictionTimer() {
    _frictionTimer = Timer(_frictionThreshold, _emitFrictionLog);
  }

  void _cancelFrictionTimer() {
    _frictionTimer?.cancel();
    _frictionTimer = null;
  }

  void _emitFrictionLog() {
    final hesitation = _focusStartTime != null
        ? DateTime.now().difference(_focusStartTime!)
        : _frictionThreshold;

    final logLine = FrictionLogger.buildLog(
      hesitation: hesitation,
      fieldName: 'parent_consent_code',
    );

    dev.log(logLine, name: 'UI_FRICTION');
    debugPrint(logLine);
  }

  void _onSubmit(ComplianceCubit cubit) {
    _cancelFrictionTimer();
    cubit.verify(
      predecessorId: _predecessorController.text.trim().isEmpty
          ? null
          : _predecessorController.text.trim(),
      lsaId: _lsaIdController.text.trim(),
      parentConsentCode: _consentController.text.trim(),
    );
  }

  void _onReset(ComplianceCubit cubit) {
    _consentController.clear();
    cubit.reset();
  }

  @override
  void dispose() {
    _cancelFrictionTimer();
    _consentFocusNode.removeListener(_onConsentFocusChanged);
    _consentController.removeListener(_onConsentTextChanged);
    _lsaIdController.dispose();
    _consentController.dispose();
    _predecessorController.dispose();
    _consentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ComplianceCubit(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<ComplianceCubit>();
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: AppBar(
                title: const Text('HabotConnect'),
                centerTitle: false,
                backgroundColor: Theme.of(context).colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              body: BlocConsumer<ComplianceCubit, ComplianceState>(
                listener: (context, state) {},
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LsaHeader(),
                        const SizedBox(height: 32),

                        // ── Status banner ──────────────────────────────
                        StatusBanner(state: state),
                        const SizedBox(height: 28),

                        // ── lsa_id ────────────────────────────────────
                        LabeledTextField(
                          label: 'LSA Identifier',
                          hint: 'e.g. LSA-7049',
                          controller: _lsaIdController,
                          readOnly: state is! ComplianceIdle,
                        ),
                        const SizedBox(height: 20),

                        // ── parent_consent_code ───────────────────────
                        LabeledTextField(
                          label: 'Parent Consent Code',
                          hint: 'Enter code — e.g. PCC-2026-9901',
                          controller: _consentController,
                          focusNode: _consentFocusNode,
                          readOnly: state is! ComplianceIdle,
                          inputFormatters: const [
                            UpperCaseTextInputFormatter(),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── predecessor_id (system — always locked) ───
                        LabeledTextField(
                          label: 'Predecessor ID',
                          controller: _predecessorController,
                          isSystemField: true,
                        ),
                        const SizedBox(height: 32),

                        // ── Primary action ─────────────────────────────
                        SubmitButton(
                          currentState: state,
                          onPressed: () => _onSubmit(cubit),
                        ),

                        // ── Reset ──────────────────────────────────────
                        if (state is ComplianceQuarantined ||
                            state is ComplianceSuccess) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => _onReset(cubit),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reset & Try Again'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        if (state is ComplianceSuccess)
                          _DebugInfoCard(traceId: state.traceId),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DebugInfoCard extends StatelessWidget {
  final String traceId;

  const _DebugInfoCard({required this.traceId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;

    final gradientColors = isDark
        ? [const Color(0xFF0D1F17), const Color(0xFF0A1810)]
        : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)];

    const accentGreen = Color(0xFF43A047);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentGreen.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 14,
                  color: accentGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Audit Trail',
                style: tt.labelMedium?.copyWith(
                  color: accentGreen,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'x-trace-id',
            style: tt.labelSmall?.copyWith(
              color: accentGreen.withValues(alpha: 0.7),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            traceId,
            style: tt.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
