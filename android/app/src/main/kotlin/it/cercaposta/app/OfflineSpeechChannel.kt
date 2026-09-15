package it.cercaposta.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Uses only the Android 12+ on-device recognizer. No default-recognizer fallback. */
class OfflineSpeechChannel(private val activity: FlutterFragmentActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "cercaposta/offline_speech")
    private var recognizer: SpeechRecognizer? = null
    private var session: String? = null
    private var permissionReply: MethodChannel.Result? = null

    companion object { const val PERMISSION_REQUEST = 49217 }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    if (!available()) result.success(false)
                    else if (ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) ==
                        PackageManager.PERMISSION_GRANTED) result.success(true)
                    else if (permissionReply != null) result.error("busy", "permission request active", null)
                    else {
                        permissionReply = result
                        activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST)
                    }
                }
                "listen" -> {
                    val id = call.argument<String>("sessionId")
                    val locale = call.argument<String>("localeId")
                    if (id.isNullOrEmpty() || locale !in setOf("it_IT", "en_US")) {
                        result.error("invalid", "invalid voice request", null)
                    } else if (!available()) result.error("unavailable", "on-device recognition unavailable", null)
                    else {
                        close()
                        session = id
                        try {
                            // Recheck immediately before construction; if the service disappears,
                            // construction fails. Never call createSpeechRecognizer here.
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
                                recognizer!!.setRecognitionListener(listener(id))
                                recognizer!!.startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale!!.replace('_', '-'))
                                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                                    putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
                                })
                                result.success(null)
                            } else result.error("unavailable", "on-device recognition unavailable", null)
                        } catch (error: Exception) {
                            close()
                            result.error(if (error is SecurityException) "permission" else "unavailable",
                                "on-device recognition failed", null)
                        }
                    }
                }
                "stop" -> {
                    if (call.argument<String>("sessionId") == session) close()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun available(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)

    fun permissionResult(requestCode: Int, grants: IntArray): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        permissionReply?.success(grants.firstOrNull() == PackageManager.PERMISSION_GRANTED && available())
        permissionReply = null
        return true
    }

    private fun event(id: String, kind: String, value: Any, isFinal: Boolean = false) {
        if (session == id) channel.invokeMethod("event", mapOf(
            "sessionId" to id, "kind" to kind, "value" to value, "final" to isFinal))
    }

    private fun listener(id: String) = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) { event(id, "status", "listening") }
        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {} // Audio never crosses the channel.
        override fun onEndOfSpeech() { event(id, "status", "notListening") }
        override fun onError(error: Int) {
            event(id, "error", if (error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) "permission" else "unavailable")
            if (session == id) close()
        }
        override fun onResults(results: Bundle?) {
            val words = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
            if (words != null) event(id, "result", words, true)
            event(id, "status", "done")
            if (session == id) close()
        }
        override fun onPartialResults(results: Bundle?) {
            val words = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
            if (words != null) event(id, "result", words)
        }
        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun close() {
        session = null
        recognizer?.cancel()
        recognizer?.destroy()
        recognizer = null
    }

    fun dispose() {
        close()
        permissionReply?.success(false)
        permissionReply = null
        channel.setMethodCallHandler(null)
    }
}
