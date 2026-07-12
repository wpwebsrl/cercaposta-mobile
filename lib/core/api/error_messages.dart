import '../i18n/app_localizations.dart';
import 'api_exception.dart';

/// Translate a backend error.code (or a thrown object) to a user-facing string.
String localizeApiError(AppLocalizations l, Object error) {
  final e = ApiException.from(error);
  switch (e.code) {
    case 'auth.invalid_credentials':
      return l.errorInvalidCredentials;
    case 'auth.account_banned':
      return l.errorAccountBanned;
    case 'auth.invalid_token':
    case 'auth.missing_token':
      return l.errorInvalidToken;
    case 'auth.invalid_refresh':
      return l.errorInvalidRefresh;
    case 'auth.forbidden':
      return l.errorForbidden;
    case 'auth.admin_not_on_mobile':
      return l.errorAdminNotOnMobile;
    case 'totp.invalid_code':
      return l.errorTotpInvalidCode;
    case 'totp.challenge_expired':
      return l.errorTotpExpired;
    case 'enc.dek_locked':
      return l.errorDekLocked;
    case 'enc.recovery_failed':
      return l.errorRecoveryFailed;
    case 'auth.weak_password':
      final violations = e.params['violations'];
      if (violations is List) {
        final labels = violations
            .whereType<String>()
            .map((c) => _passwordViolationLabel(l, c))
            .where((s) => s.isNotEmpty)
            .toList();
        if (labels.isNotEmpty) {
          return l.errorWeakPasswordDetail(labels.join(', '));
        }
      }
      return l.errorWeakPassword;
    case 'chat.not_configured':
      return l.errorChatNotConfigured;
    case 'chat.llm_error':
      return l.errorChatLlmError(e.detail ?? '');
    case 'followup.not_remindable':
      return l.errorFollowupNotRemindable;
    case 'followup.not_configured':
      return l.errorFollowupNotConfigured;
    case 'followup.draft_failed':
      return l.errorFollowupDraftFailed;
    case 'followup.send_no_source':
      return l.errorFollowupSendNoSource;
    case 'sources.send_consent_required':
      return l.errorSendConsentRequired;
    case 'mail.auth_failed':
      return l.errorMailAuthFailed;
    case 'mail.send_failed':
      return l.errorMailSendFailed;
    case 'common.not_found':
      return l.errorNotFound;
    case 'messages.preview_unsupported':
      return l.errorPreviewUnsupported;
    case 'messages.preview_failed':
      return l.errorPreviewFailed;
    case 'messages.raw_missing':
      return l.errorRawMissing;
    case 'common.validation_error':
      return l.errorValidation;
    case 'common.network':
      return l.errorNetwork;
    default:
      return l.errorGeneric;
  }
}

/// Human label for one password-policy violation code (backend
/// core/security.password_policy_violations), so the app lists what's missing
/// instead of a bare "too weak".
String _passwordViolationLabel(AppLocalizations l, String code) {
  switch (code) {
    case 'min_length':
      return l.pwMinLength;
    case 'require_lower':
      return l.pwRequireLower;
    case 'require_upper':
      return l.pwRequireUpper;
    case 'require_digit':
      return l.pwRequireDigit;
    case 'require_symbol':
      return l.pwRequireSymbol;
    case 'min_char_classes':
      return l.pwMinCharClasses;
    default:
      return '';
  }
}
