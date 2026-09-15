package it.cercaposta.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// FlutterFragmentActivity (non FlutterActivity) è richiesto da local_auth:
// BiometricPrompt necessita di una FragmentActivity host.
class MainActivity : FlutterFragmentActivity() {
    private var offlineSpeech: OfflineSpeechChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        offlineSpeech = OfflineSpeechChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (offlineSpeech?.permissionResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        offlineSpeech?.dispose()
        offlineSpeech = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
