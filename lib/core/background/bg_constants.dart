/// Keys shared between the foreground app and the background notification isolate
/// (docs/notifiche.md → "Notifiche di sistema operativo"). They must match exactly on both
/// sides, so they live in one place instead of being duplicated as string literals.
library;

/// SharedPreferences keys.
const String kPrefOsNotifications =
    'pref_os_notifications'; // bool, default false (opt-in)
const String kPrefLocale =
    'pref_locale'; // the app's locale code (settings_controller)
const String kBgSeenIds =
    'bg_seen_ids'; // JSON list<String> of already-notified ids
const String kBgBaselineMs =
    'bg_baseline_ms'; // epoch ms; only newer notifications count
const String kBgLastRev =
    'bg_last_notif_rev'; // last notifications revision we acted on
const String kBgHeartbeatMs =
    'bg_heartbeat_ms'; // last foreground live-refresh tick (epoch ms)
const String kBgRotated =
    'bg_rotated'; // bool: the isolate rotated the tokens; adopt on resume
const String kBgRefreshStartedMs =
    'bg_refresh_started_ms'; // epoch ms a bg refresh began

/// Secure storage key for the access token the background isolate minted (adopted on resume so
/// the foreground doesn't refresh again and race the isolate).
const String kSecBgAccessToken = 'bg_access_token';

/// WorkManager task identity (Android unique name + iOS BGTaskScheduler identifier).
const String kBgTaskName = 'cercaposta_notify_poll';
const String kBgTaskIosId = 'it.cercaposta.app.notifyfetch';

/// The foreground is considered "recently active" for this long after its last heartbeat: the
/// background isolate must NOT refresh tokens within this window, to avoid racing a foreground
/// refresh into a reuse-detection logout.
const Duration kForegroundActiveWindow = Duration(minutes: 5);

/// Cap on remembered ids, so bg_seen_ids can't grow without bound.
const int kBgSeenCap = 200;

/// Android notification channel.
const String kNotifChannelId = 'notifications';
