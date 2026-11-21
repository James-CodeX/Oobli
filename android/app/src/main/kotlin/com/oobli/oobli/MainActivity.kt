package com.oobli.oobli

import android.Manifest
import android.content.pm.PackageManager
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "readInbox" -> {
                    val since = call.argument<Number>("since")?.toLong() ?: 0L
                    val senders = call.argument<List<String>>("senders").orEmpty()
                    val limit = call.argument<Number>("limit")?.toInt() ?: 3000
                    readInbox(since, senders, limit, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Reads inbox SMS newer than [since] whose sender matches one of [senders]
     * (normalised, case-insensitive). Runs off the main thread; personal
     * messages are dropped here and never cross into Dart.
     */
    private fun readInbox(since: Long, senders: List<String>, limit: Int, result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "READ_SMS permission not granted", null)
            return
        }
        executor.execute {
            try {
                val patterns = senders.map { normalise(it) }.filter { it.isNotEmpty() }
                val out = ArrayList<Map<String, Any>>()
                contentResolver.query(
                    Telephony.Sms.Inbox.CONTENT_URI,
                    arrayOf(Telephony.Sms._ID, Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE),
                    "${Telephony.Sms.DATE} > ?",
                    arrayOf(since.toString()),
                    "${Telephony.Sms.DATE} DESC",
                )?.use { cursor ->
                    val idCol = cursor.getColumnIndexOrThrow(Telephony.Sms._ID)
                    val addressCol = cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
                    val bodyCol = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
                    val dateCol = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)
                    while (cursor.moveToNext() && out.size < limit) {
                        val address = cursor.getString(addressCol) ?: continue
                        val normalised = normalise(address)
                        val isFinancial = patterns.any { p -> if (p == "mpesa") normalised == p else normalised.contains(p) }
                        if (!isFinancial) continue
                        out.add(
                            mapOf(
                                "id" to cursor.getLong(idCol).toString(),
                                "address" to address,
                                "body" to (cursor.getString(bodyCol) ?: ""),
                                "date" to cursor.getLong(dateCol),
                            ),
                        )
                    }
                }
                runOnUiThread { result.success(out) }
            } catch (e: Exception) {
                runOnUiThread { result.error("READ_FAILED", e.message, null) }
            }
        }
    }

    private fun normalise(value: String) = value.lowercase().filter { it.isLetterOrDigit() }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "com.oobli.oobli/sms"
    }
}
