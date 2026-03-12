package com.example.samenbank

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
                            // Some providers (e.g. cloud document providers) do not
                            // expose JSON with a strict MIME type. Use a broad type
                            // plus MIME hints so files remain selectable.
                            type = "*/*"
                            putExtra(
                                Intent.EXTRA_MIME_TYPES,
                                arrayOf(
                                    "application/json",
                                    "text/json",
                                    "text/plain",
                                ),
                            )
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        }
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, pickJsonRequestCode)
                    }

                    "createWorkingCopyJsonDocument" -> {
                        if (pendingPickResult != null) {
                            result.error(
                                "picker_busy",
                                "Ein anderer Dateidialog ist noch aktiv.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        val fileNameArg = call.argument<String>("fileName")
                        val fileName = if (fileNameArg.isNullOrBlank()) {
                            "samenbank_app_format_v1.json"
                        } else {
                            fileNameArg
                        }
                        pendingPickResult = result
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_TITLE, fileName)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        }
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, createJsonRequestCode)
                    }

                    "canReadUri" -> {
                        val uri = parseUriArg(call.argument<String>("uri"), result) ?: return@setMethodCallHandler
                        runOnIo(
                            result = result,
                            ioErrorCode = "read_check_failed",
                            block = { canReadUri(uri) },
                        )
                    }

                    "readUri" -> {
                        val uri = parseUriArg(call.argument<String>("uri"), result) ?: return@setMethodCallHandler
                        runOnIo(
                            result = result,
                            ioErrorCode = "read_failed",
                            block = { readUri(uri) },
                        )
                    }

                    "writeUri" -> {
                        val uri = parseUriArg(call.argument<String>("uri"), result) ?: return@setMethodCallHandler
                        val content = call.argument<String>("content")
                        if (content == null) {
                            result.error("invalid_args", "Fehlender Inhalt.", null)
                            return@setMethodCallHandler
                        }
                        runOnIo(
                            result = result,
                            ioErrorCode = "write_failed",
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

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != pickJsonRequestCode && requestCode != createJsonRequestCode) {
            return
        }

        val result = pendingPickResult ?: return
        pendingPickResult = null

        if (resultCode != RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }

        try {
            takePersistablePermission(uri)
            result.success(uri.toString())
        } catch (error: SecurityException) {
            result.error("persist_permission_failed", error.message, null)
        }
    }

    private fun parseUriArg(rawUri: String?, result: MethodChannel.Result): Uri? {
        if (rawUri.isNullOrBlank()) {
            result.error("invalid_args", "Ungültige URI.", null)
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
        val readFlag = Intent.FLAG_GRANT_READ_URI_PERMISSION
        val writeFlag = Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        try {
            contentResolver.takePersistableUriPermission(uri, readFlag or writeFlag)
        } catch (_: SecurityException) {
            contentResolver.takePersistableUriPermission(uri, readFlag)
        }
    }

    private fun canReadUri(uri: Uri): Boolean {
        return try {
            contentResolver.openInputStream(uri)?.use { stream ->
                stream.read(ByteArray(1))
            } != null
        } catch (_: Exception) {
            false
        }
    }

    private fun <T> runOnIo(
        result: MethodChannel.Result,
        ioErrorCode: String,
        block: () -> T,
    ) {
        ioExecutor.execute {
            try {
                val value = block()
                mainHandler.post {
                    result.success(value)
                }
            } catch (error: IOException) {
                mainHandler.post {
                    result.error(ioErrorCode, error.message, null)
                }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("unexpected_error", error.message, null)
                }
            }
        }
    }

    @Throws(IOException::class)
    private fun readUri(uri: Uri): String {
        val stream = contentResolver.openInputStream(uri)
            ?: throw IOException("Datei konnte nicht geöffnet werden.")
        stream.bufferedReader(Charsets.UTF_8).use { reader ->
            return reader.readText()
        }
    }

    @Throws(IOException::class)
    private fun writeUri(uri: Uri, content: String) {
        val stream = contentResolver.openOutputStream(uri, "wt")
            ?: throw IOException("Datei konnte nicht zum Schreiben geöffnet werden.")
        stream.bufferedWriter(Charsets.UTF_8).use { writer ->
            writer.write(content)
            writer.flush()
        }
    }
}
