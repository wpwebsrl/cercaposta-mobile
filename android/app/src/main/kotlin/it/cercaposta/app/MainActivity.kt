package it.cercaposta.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (non FlutterActivity) è richiesto da local_auth:
// BiometricPrompt necessita di una FragmentActivity host.
class MainActivity : FlutterFragmentActivity()
