package app.saatenschluessel

import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "samenbank/working_copy_saf"
    private val pickJsonRequestCode = 40021
    private val createJsonRequestCode = 40022
    private var pendingPickResult: MethodChannel.Result? = null
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onDestroy() {
        ioExecutor.shutdown()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickWorkingCopyJsonDocument" -> {
                        if (pendingPickResult != null) {
                            result.error(
                                "picker_busy",
                                "Ein anderer Dateidialog ist noch aktiv.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        pendingPickResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                        }
                        startActivityForResult(intent, pickJsonRequestCode)
                    }
                    "createWorkingCopyJsonDocument" -> {
                        val suggestedName = call.argument<String>("suggestedName")
                            ?: "samenbank_app_format_v1.json"
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_TITLE, suggestedName)
                        }
                        pendingPickResult = result
                        startActivityForResult(intent, createJsonRequestCode)
                    }
                    "takePersistablePermission" -> {
                        val uri = parseUriArg(call.argument("uri"), result)
                            ?: return@setMethodCallHandler
                        runCatching {
                            takePersistablePermission(uri)
                        }.onSuccess {
                            result.success(null)
                        }.onFailure { error ->
                            result.error("persist_failed", error.message, null)
                        }
                    }
                    "canReadUri" -> {
                        val uri = parseUriArg(call.argument("uri"), result)
                            ?: return@setMethodCallHandler
                        result.success(canReadUri(uri))
                    }
                    "readUri" -> {
                        val uri = parseUriArg(call.argument("uri"), result)
                            ?: return@setMethodCallHandler
                        runOnIo(
                            result = result,
                            block = { readUri(uri) },
                        )
                    }
                    "writeUri" -> {
                        val uri = parseUriArg(call.argument("uri"), result)
                            ?: return@setMethodCallHandler
                        val content = call.argument<String>("content")
                        if (content == null) {
                            result.error("missing_content", "Inhalt fehlt.", null)
                            return@setMethodCallHandler
                        }
                        runOnIo(
                            result = result,
                            block = {
                                writeUri(uri, content)
                                null
                            },
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != pickJsonRequestCode && requestCode != createJsonRequestCode) {
            return
        }

        val result = pendingPickResult
        pendingPickResult = null

        if (result == null) {
            return
        }

        if (resultCode != RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.error("missing_uri", "Keine Datei ausgewaehlt.", null)
            return
        }

        result.success(uri.toString())
    }

    private fun parseUriArg(rawUri: String?, result: MethodChannel.Result): Uri? {
        if (rawUri.isNullOrBlank()) {
            result.error("missing_uri", "URI fehlt.", null)
            return null
        }
        return try {
            Uri.parse(rawUri)
        } catch (error: Exception) {
            result.error("invalid_uri", error.message, null)
            null
        }
    }

    private fun takePersistablePermission(uri: Uri) {
        contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )
    }

    private fun canReadUri(uri: Uri): Boolean {
        return try {
            contentResolver.openInputStream(uri)?.use { true } ?: false
        } catch (_: Exception) {
            false
        }
    }

    private fun <T> runOnIo(
        result: MethodChannel.Result,
        block: () -> T,
    ) {
        ioExecutor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (error: IOException) {
                mainHandler.post { result.error("io_error", error.message, null) }
            } catch (error: SecurityException) {
                mainHandler.post { result.error("permission_denied", error.message, null) }
            } catch (error: Exception) {
                mainHandler.post { result.error("unexpected_error", error.message, null) }
            }
        }
    }

    private fun readUri(uri: Uri): String {
        return contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
            ?: throw IOException("Datei konnte nicht gelesen werden.")
    }

    private fun writeUri(uri: Uri, content: String) {
        contentResolver.openOutputStream(uri, "wt")?.bufferedWriter()?.use {
            it.write(content)
        } ?: throw IOException("Datei konnte nicht geschrieben werden.")
    }
}
