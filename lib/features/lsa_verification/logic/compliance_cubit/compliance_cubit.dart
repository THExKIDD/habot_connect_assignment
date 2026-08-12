import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habot_connect_assignment/core/exceptions/lineage_exception.dart';
import 'package:habot_connect_assignment/features/lsa_verification/logic/compliance_cubit/compliance_state.dart';
import '../../models/verification_request.dart';
import '../../repositories/compliance_repository.dart';
import '../header_builder.dart';
import '../lineage_validator.dart';

/// State layer — manages compliance verification workflow states.
///
/// Emits four discrete states: [ComplianceIdle], [ComplianceProcessing],
/// [ComplianceQuarantined], [ComplianceSuccess].
///
/// Strictly enforces fail-closed operations using [ComplianceRepository].
class ComplianceCubit extends Cubit<ComplianceState> {
  final ComplianceRepository _repository;

  ComplianceCubit({ComplianceRepository? repository})
      : _repository = repository ?? ComplianceRepository(),
        super(const ComplianceIdle());

  /// Runs compliance verification pipeline with production error handling.
  Future<void> verify({
    required String? predecessorId,
    required String lsaId,
    required String parentConsentCode,
  }) async {
    // ── Step 1: Data Lineage Gate ─────────────────────────────────────────
    try {
      LineageValidator.validate(predecessorId);
    } on LineageException catch (e) {
      emit(ComplianceQuarantined(e.message));
      return;
    }

    // ── Step 2: Build Payload & Headers ───────────────────────────────────
    final request = VerificationRequest(
      predecessorId: predecessorId!,
      lsaId: lsaId,
      parentConsentCode: parentConsentCode,
      timestampUtc: DateTime.now().toUtc().toIso8601String(),
    );

    final headers = HeaderBuilder.build(request);

    // ── Step 3: Transition UI to Processing ─────────────────────────────
    emit(const ComplianceProcessing());

    // ── Step 4: Execute Repository Request ────────────────────────────────
    try {
      await _repository.verifyCompliance(
        request: request,
        traceId: headers.traceId,
        logicHash: headers.logicHash,
      );
      emit(ComplianceSuccess(headers.traceId));
    } on LineageException catch (e) {
      // Production fail-closed halt: display formatted quarantine reason
      emit(ComplianceQuarantined(e.message));
    } catch (e) {
      // Unhandled catch-all fallback
      emit(ComplianceQuarantined(
        'Data Quarantined — Compliance Failure ($e)',
      ));
    }
  }

  /// Resets state back to [ComplianceIdle] to allow retry.
  void reset() => emit(const ComplianceIdle());
}
