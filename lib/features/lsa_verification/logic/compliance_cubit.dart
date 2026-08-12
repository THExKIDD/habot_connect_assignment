import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/compliance_state.dart';
import '../models/lineage_exception.dart';
import '../models/verification_request.dart';
import '../logic/lineage_validator.dart';
import '../logic/header_builder.dart';
import '../services/compliance_api_service.dart';

/// State layer — orchestrates the full compliance verification pipeline.
///
/// Emits exactly one of four states: [ComplianceIdle], [ComplianceProcessing],
/// [ComplianceQuarantined], [ComplianceSuccess].
///
/// Fail-closed contract:
/// - Any [LineageException] → emit [ComplianceQuarantined] immediately,
///   no network call fires.
/// - Any API error (500, null status, timeout, or [DioException]) →
///   emit [ComplianceQuarantined] with the compliance-failure message.
/// - No silent fallbacks, no default values that allow execution to continue.
class ComplianceCubit extends Cubit<ComplianceState> {
  final ComplianceApiService _apiService;

  ComplianceCubit({ComplianceApiService? apiService})
      : _apiService = apiService ?? ComplianceApiService(),
        super(const ComplianceIdle());

  /// Runs the full pipeline for the given form inputs.
  ///
  /// Order of operations:
  /// 1. Lineage gate — validate [predecessorId] (fail-closed on null/empty).
  /// 2. Build metadata headers (trace_id + logic_hash).
  /// 3. Construct the request payload.
  /// 4. Emit [ComplianceProcessing] — locks the UI.
  /// 5. Send the API call via [ComplianceApiService].
  /// 6. On success → emit [ComplianceSuccess].
  ///    On any failure → emit [ComplianceQuarantined] (fail-closed).
  Future<void> verify({
    required String? predecessorId,
    required String lsaId,
    required String parentConsentCode,
  }) async {
    // ── Step 1: Lineage gate ──────────────────────────────────────────────
    try {
      validateLineage(predecessorId);
    } on LineageException catch (e) {
      // Fail-closed: block network call, quarantine immediately.
      emit(ComplianceQuarantined(e.message));
      return;
    }

    // ── Step 2: Build request & headers ──────────────────────────────────
    final request = VerificationRequest(
      predecessorId: predecessorId!, // safe: validated above
      lsaId: lsaId,
      parentConsentCode: parentConsentCode,
      timestampUtc: DateTime.now().toUtc().toIso8601String(),
    );

    final headers = buildHeaders(request);

    // ── Step 3: Lock UI ───────────────────────────────────────────────────
    emit(const ComplianceProcessing());

    // ── Step 4: API call ──────────────────────────────────────────────────
    try {
      await _apiService.verify(
        request: request,
        traceId: headers.traceId,
        logicHash: headers.logicHash,
      );
      emit(ComplianceSuccess(headers.traceId));
    } catch (_) {
      // Fail-closed: any exception (DioException, null status, timeout) →
      // purge in-memory state, lock submit, display compliance failure.
      emit(const ComplianceQuarantined(
        'Data Quarantined — Compliance Failure',
      ));
    }
  }

  /// Resets back to [ComplianceIdle] so the form can be retried.
  void reset() => emit(const ComplianceIdle());
}
