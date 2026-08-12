import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/friction_logger.dart';
import '../logic/compliance_cubit.dart';
import '../models/compliance_state.dart';
import '../widgets/header.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/status_banner.dart';
import '../widgets/submit_button.dart';

/// Composition-only screen — assembles UI Byts and wires them to state.
///
/// Responsibilities of this layer ONLY:
/// - Provide [ComplianceCubit] via [BlocProvider].
/// - Hold [TextEditingController]s and [FocusNode]s (lifecycle only, not logic).
/// - Wire the friction timer: attach a listener to [_consentFocusNode] that
///   starts a debounce [Timer] on focus; if the user stalls > 5 s without
///   typing or submitting, emit the friction log to the debug stream.
/// - Forward user actions to [ComplianceCubit].
///
/// NO business logic here. No null checks, no validation, no API calls.
/// All of that lives in the Cubit and Logic Byts.
class LsaVerificationScreen extends StatefulWidget {
  const LsaVerificationScreen({super.key});

  @override
  State<LsaVerificationScreen> createState() => _LsaVerificationScreenState();
}

/// State is used ONLY for lifecycle management of controllers/timers/focus nodes.
/// The UI itself rebuilds via BlocBuilder — no setState drives the visual tree.
class _LsaVerificationScreenState extends State<LsaVerificationScreen> {
  // ── System-prefilled field (read-only per spec) ──────────────────────
  static const String _kPredecessorId = 'PRED-9982-XYZ';

  // ── Controllers ───────────────────────────────────────────────────────
  final TextEditingController _lsaIdController =
      TextEditingController(text: 'LSA-7049');
  final TextEditingController _consentController = TextEditingController();
  final TextEditingController _predecessorController =
      TextEditingController(text: _kPredecessorId);

  // ── Focus node for friction logging ───────────────────────────────────
  final FocusNode _consentFocusNode = FocusNode();

  // ── Friction timer ─────────────────────────────────────────────────────
  Timer? _frictionTimer;
  DateTime? _focusStartTime;
  static const Duration _frictionThreshold = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _consentFocusNode.addListener(_onConsentFocusChanged);
    _consentController.addListener(_onConsentTextChanged);
  }

  /// Starts the friction timer when the field gains focus;
  /// cancels it when focus is lost.
  void _onConsentFocusChanged() {
    if (_consentFocusNode.hasFocus) {
      _focusStartTime = DateTime.now();
      _startFrictionTimer();
    } else {
      _cancelFrictionTimer();
    }
  }

  /// Any keystroke resets the friction timer — the user is actively typing.
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

  /// Fired by the timer when the user has stalled for > 5 seconds.
  /// Calls the pure [buildFrictionLog] Logic Byt for formatting,
  /// then outputs to the debug stream — side effect stays here.
  void _emitFrictionLog() {
    final hesitation = _focusStartTime != null
        ? DateTime.now().difference(_focusStartTime!)
        : _frictionThreshold;

    final logLine = buildFrictionLog(
      hesitation: hesitation,
      fieldName: 'parent_consent_code',
    );

    // Output to debug console / stream (visible in flutter logs).
    dev.log(logLine, name: 'UI_FRICTION');
    // ignore: avoid_print
    debugPrint(logLine);
  }

  void _onSubmit(ComplianceCubit cubit) {
    // Cancel friction timer on submit — user took action.
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
                listener: (context, state) {
                  // BlocListener handles side-effects like snackbars/navigation.
                  // Currently no navigation side-effect needed.
                },
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

                        // ── lsa_id (prefilled, editable) ───────────────
                        LabeledTextField(
                          label: 'LSA Identifier',
                          hint: 'e.g. LSA-7049',
                          controller: _lsaIdController,
                          readOnly: state is! ComplianceIdle,
                        ),
                        const SizedBox(height: 20),

                        // ── parent_consent_code (user-entered) ─────────
                        LabeledTextField(
                          label: 'Parent Consent Code',
                          hint: 'Enter code — e.g. PCC-2026-9901',
                          controller: _consentController,
                          focusNode: _consentFocusNode,
                          readOnly: state is! ComplianceIdle,
                        ),
                        const SizedBox(height: 20),

                        // ── predecessor_id (system, read-only) ──────────
                        LabeledTextField(
                          label: 'Predecessor ID (System)',
                          hint: 'System-assigned lineage reference',
                          controller: _predecessorController,
                          readOnly: true,
                        ),
                        const SizedBox(height: 32),

                        // ── Primary action ─────────────────────────────
                        SubmitButton(
                          currentState: state,
                          onPressed: () => _onSubmit(cubit),
                        ),

                        // ── Reset (visible after quarantine or success) ─
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

                        // ── Debug info card (shows trace ID for demo) ──
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

/// UI Byt — debug information card shown in Success state for the demo.
/// Displays the x-trace-id for audit reference.
class _DebugInfoCard extends StatelessWidget {
  final String traceId;

  const _DebugInfoCard({required this.traceId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Audit Trail',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'x-trace-id',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            traceId,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
