package com.oobli.oobli

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "canInstall" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls(),
                    )
                    "openInstallSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(null)
                    }
                    "install" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("BAD_ARGS", "path is required", null)
                        } else {
                            installApk(File(path))
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("UPDATE_FAILED", e.message, null)
            }
        }
    }

    /** Opens the system installer for a downloaded update (the user confirms). */
    private fun installApk(apk: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
        startActivity(
            Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK),
        )
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
        private const val UPDATE_CHANNEL = "com.oobli.oobli/update"
    }
}
