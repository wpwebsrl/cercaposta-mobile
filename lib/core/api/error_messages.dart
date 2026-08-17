import '../i18n/app_localizations.dart';
import 'package:passkeys/types.dart';

import 'api_exception.dart';

String localizePasskeyError(AppLocalizations l, Object error) {
  if (error is PasskeyAuthCancelledException) {
    return l.passkeyErrorCancelled;
  }
  if (error is NoCredentialsAvailableException) {
    return l.passkeyErrorNoCredential;
  }
  if (error is DomainNotAssociatedException) {
    return l.passkeyErrorDomainNotAssociated;
  }
  if (error is DeviceNotSupportedException ||
      error is PasskeyUnsupportedException ||
      error is MissingGoogleSignInException ||
      error is SyncAccountNotAvailableException ||
      error is NoCreateOptionException) {
    return l.passkeyErrorUnavailable;
  }
  if (error is TimeoutException) return l.passkeyErrorTimeout;
  if (error is AuthenticatorException) return l.passkeyErrorUnavailable;
  return localizeApiError(l, error);
}

/// Translate a backend error.code (or a thrown object) to a user-facing string.
String localizeApiError(AppLocalizations l, Object error) {
  final e = ApiException.from(error);
  switch (e.code) {
    case 'google.cancelled':
      return l.googleErrorCancelled;
    case 'google.state':
      return l.googleErrorState;
    case 'google.configuration':
      return l.googleErrorConfiguration;
    case 'google.identity':
      return l.googleErrorIdentity;
    case 'google.link_required':
      return l.googleErrorLinkRequired;
    case 'google.registration_required':
      return l.googleErrorRegistrationRequired;
    case 'google.inactive':
      return l.googleErrorInactive;
    case 'google.invalid':
    case 'google.token_exchange':
    case 'google.code_invalid':
    case 'registration.native_code_invalid':
      return l.googleErrorInvalid;
    case 'registration.google_disabled':
      return l.googleErrorDisabled;
    case 'registration.google_not_configured':
    case 'registration.native_callback_invalid':
    case 'google.browser_open_failed':
    case 'google.unavailable':
      return l.googleErrorUnavailable;
    case 'apple.cancelled':
      return l.appleErrorCancelled;
    case 'apple.state':
    case 'registration.apple_state_invalid':
      return l.appleErrorState;
    case 'apple.identity':
    case 'registration.apple_identity_invalid':
      return l.appleErrorIdentity;
    case 'apple.link_required':
    case 'registration.apple_link_required':
      return l.appleErrorLinkRequired;
    case 'apple.registration_required':
    case 'registration.apple_registration_required':
      return l.appleErrorRegistrationRequired;
    case 'apple.inactive':
      return l.appleErrorInactive;
    case 'apple.invalid':
    case 'apple.token_exchange':
    case 'apple.code_invalid':
    case 'registration.apple_code_invalid':
    case 'registration.apple_token_exchange':
    case 'registration.apple_token_exchange_failed':
      return l.appleErrorInvalid;
    case 'registration.apple_disabled':
      return l.appleErrorDisabled;
    case 'registration.apple_not_configured':
    case 'registration.apple_native_callback_invalid':
    case 'apple.browser_open_failed':
    case 'apple.unavailable':
      return l.appleErrorUnavailable;
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
    case 'passkeys.invalid':
      return l.passkeyErrorInvalid;
    case 'passkeys.not_configured':
      return l.passkeyErrorNotConfigured;
    case 'passkeys.origin_not_allowed':
      return l.passkeyErrorDomainNotAssociated;
    case 'passkeys.already_registered':
      return l.passkeyErrorAlreadyRegistered;
    case 'passkeys.challenge_expired':
      return l.passkeyErrorTimeout;
    case 'passkeys.temporarily_unavailable':
      return l.passkeyErrorUnavailable;
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
    // The two the «mark as awaiting» sheet raises most: without these the user would
    // get «errore generico» on the one refusal that is actually actionable.
    case 'followup.already_active':
      return l.errorFollowupAlreadyActive;
    case 'followup.no_counterpart':
      return l.errorFollowupNoCounterpart;
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
