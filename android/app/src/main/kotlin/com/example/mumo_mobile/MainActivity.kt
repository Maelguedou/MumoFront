package com.example.mumo_mobile

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "mumo_agent/downloads"
    private val downloadsPermissionRequestCode = 7401
    private var pendingDownload: PendingDownload? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveFileToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val fileName = call.argument<String>("fileName")
            val mimeType = call.argument<String>("mimeType")
            val bytes = call.argument<ByteArray>("bytes")

            if (fileName.isNullOrBlank() || mimeType.isNullOrBlank() || bytes == null) {
                result.error(
                    "INVALID_DOWNLOAD_ARGUMENTS",
                    "Paramètres de téléchargement invalides.",
                    null
                )
                return@setMethodCallHandler
            }

            if (needsLegacyStoragePermission()) {
                pendingDownload = PendingDownload(fileName, mimeType, bytes)
                pendingResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                    downloadsPermissionRequestCode
                )
                return@setMethodCallHandler
            }

            try {
                val savedPath = saveFileToDownloads(fileName, mimeType, bytes)
                result.success(savedPath)
            } catch (exception: Exception) {
                result.error(
                    "DOWNLOAD_FAILED",
                    exception.message ?: "Impossible d'enregistrer le fichier.",
                    null
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != downloadsPermissionRequestCode) return

        val download = pendingDownload
        val result = pendingResult
        pendingDownload = null
        pendingResult = null

        if (download == null || result == null) return

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED

        if (!granted) {
            result.error(
                "DOWNLOAD_PERMISSION_DENIED",
                "Permission de stockage refusée.",
                null
            )
            return
        }

        try {
            val savedPath = saveFileToDownloads(
                download.fileName,
                download.mimeType,
                download.bytes
            )
            result.success(savedPath)
        } catch (exception: Exception) {
            result.error(
                "DOWNLOAD_FAILED",
                exception.message ?: "Impossible d'enregistrer le fichier.",
                null
            )
        }
    }

    private fun needsLegacyStoragePermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) != PackageManager.PERMISSION_GRANTED
    }

    private fun saveFileToDownloads(
        fileName: String,
        mimeType: String,
        bytes: ByteArray
    ): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveWithMediaStore(fileName, mimeType, bytes)
        } else {
            saveLegacy(fileName, bytes)
        }
    }

    private fun saveWithMediaStore(
        fileName: String,
        mimeType: String,
        bytes: ByteArray
    ): String {
        val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/MumoAgent"
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Impossible de créer le fichier.")

        resolver.openOutputStream(uri)?.use { outputStream ->
            outputStream.write(bytes)
        } ?: throw IllegalStateException("Impossible d'écrire le fichier.")

        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)

        return "Téléchargements/MumoAgent/$fileName"
    }

    private fun saveLegacy(fileName: String, bytes: ByteArray): String {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        val appDir = File(downloadsDir, "MumoAgent").apply { mkdirs() }
        val file = File(appDir, fileName)

        FileOutputStream(file).use { outputStream ->
            outputStream.write(bytes)
        }

        return file.absolutePath
    }

    private data class PendingDownload(
        val fileName: String,
        val mimeType: String,
        val bytes: ByteArray
    )
}
