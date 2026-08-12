package com.statussaver.app

import android.content.ActivityNotFoundException
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "status_saver/native"
        private const val REQUEST_SAF = 4821
        private const val REQUEST_PERMISSION = 4822
        private const val PREFS = "status_saver_prefs"
        private const val KEY_SAF_URI = "saf_tree_uri"
        private const val SAVE_DIR = "Status Saver"
        private const val SAVE_PREFIX = "StatusSaver_"
        private const val THUMB_SIZE = 512
        private const val WHATSAPP = "com.whatsapp"
        private const val WHATSAPP_BUSINESS = "com.whatsapp.w4b"
    }

    private val executor = Executors.newFixedThreadPool(3)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingSafResult: MethodChannel.Result? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    private val storagePermissions: Array<String>
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                android.Manifest.permission.READ_MEDIA_IMAGES,
                android.Manifest.permission.READ_MEDIA_VIDEO,
            )
        } else {
            arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE)
        }

    private val imageExtensions = setOf("jpg", "jpeg", "png", "webp", "heic", "gif")
    private val videoExtensions = setOf("mp4", "3gp", "mkv", "webm", "mov", "avi")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getEnvironment" -> result.success(getEnvironment())
                "listStatuses" -> runAsync(result) { listStatuses() }
                "requestSafAccess" -> requestSafAccess(result)
                "clearSafAccess" -> result.success(clearSafAccess())
                "checkStoragePermission" -> result.success(hasStoragePermission())
                "requestStoragePermission" -> requestStoragePermission(result)
                "openAppSettings" -> result.success(openAppSettings())
                "getThumbnail" -> {
                    val path = call.argument<String>("path")
                    val uri = call.argument<String>("uri")
                    val type = call.argument<String>("type") ?: "image"
                    val key = call.argument<String>("key") ?: (path ?: uri ?: "")
                    runAsync(result) { getThumbnail(path, uri, type, key) }
                }
                "getPlayableFile" -> {
                    val path = call.argument<String>("path")
                    val uri = call.argument<String>("uri")
                    val name = call.argument<String>("name") ?: "media"
                    runAsync(result) { getPlayableFile(path, uri, name) }
                }
                "saveToGallery" -> {
                    val path = call.argument<String>("path")
                    val uri = call.argument<String>("uri")
                    val name = call.argument<String>("name") ?: "status"
                    val type = call.argument<String>("type") ?: "image"
                    runAsync(result) { saveToGallery(path, uri, name, type) }
                }
                "listSaved" -> runAsync(result) { listSaved() }
                "deleteSaved" -> {
                    val uri = call.argument<String>("uri")
                    runAsync(result) { deleteSaved(uri) }
                }
                "shareMedia" -> {
                    val path = call.argument<String>("path")
                    val uri = call.argument<String>("uri")
                    val mime = call.argument<String>("mime") ?: "*/*"
                    val target = call.argument<String>("targetPackage")
                    val title = call.argument<String>("title") ?: "Share"
                    result.success(shareMedia(path, uri, mime, target, title))
                }
                "openMedia" -> {
                    val uri = call.argument<String>("uri")
                    val path = call.argument<String>("path")
                    val mime = call.argument<String>("mime") ?: "*/*"
                    result.success(openMedia(path, uri, mime))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun <T> runAsync(result: MethodChannel.Result, block: () -> T) {
        executor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Exception) {
                mainHandler.post { result.error("native_error", e.message, null) }
            }
        }
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    // ------------------------------------------------------------------
    // Environment
    // ------------------------------------------------------------------

    private fun isInstalled(pkg: String): Boolean = try {
        packageManager.getPackageInfo(pkg, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun getEnvironment(): Map<String, Any?> = mapOf(
        "sdkInt" to Build.VERSION.SDK_INT,
        "whatsappInstalled" to isInstalled(WHATSAPP),
        "businessInstalled" to isInstalled(WHATSAPP_BUSINESS),
        "hasSafGrant" to (persistedSafTree() != null),
        "canReadDirect" to statusDirCandidates().any { dir ->
            dir.isDirectory && dir.canRead() && (dir.listFiles() != null)
        }
    )

    // ------------------------------------------------------------------
    // Status scanning
    // ------------------------------------------------------------------

    private fun statusDirCandidates(): List<File> {
        val ext = Environment.getExternalStorageDirectory()
        return listOf(
            File(ext, "Android/media/$WHATSAPP/WhatsApp/Media/.Statuses"),
            File(ext, "Android/media/$WHATSAPP_BUSINESS/WhatsApp Business/Media/.Statuses"),
            File(ext, "WhatsApp/Media/.Statuses"),
            File(ext, "WhatsApp Business/Media/.Statuses"),
        )
    }

    private fun mediaTypeFor(name: String): String? {
        val ext = name.substringAfterLast('.', "").lowercase()
        return when {
            imageExtensions.contains(ext) -> "image"
            videoExtensions.contains(ext) -> "video"
            else -> null
        }
    }

    private fun listStatuses(): List<Map<String, Any?>> {
        val seen = LinkedHashMap<String, Map<String, Any?>>()

        // Source 1: direct file access (works on older Android versions and
        // on devices where Android/media of other apps is still readable).
        for (dir in statusDirCandidates()) {
            val files = try {
                if (dir.isDirectory && dir.canRead()) dir.listFiles() else null
            } catch (e: SecurityException) {
                null
            } ?: continue
            for (file in files) {
                val name = file.name ?: continue
                if (name.startsWith(".")) continue
                val type = mediaTypeFor(name) ?: continue
                if (!file.canRead() || file.length() == 0L) continue
                seen.putIfAbsent(name, mapOf(
                    "id" to md5(name),
                    "name" to name,
                    "path" to file.absolutePath,
                    "uri" to null,
                    "type" to type,
                    "modified" to file.lastModified(),
                    "size" to file.length(),
                ))
            }
        }

        // Source 2: Storage Access Framework grant (Android 11+ scoped storage).
        val tree = persistedSafTree()
        if (tree != null) {
            val docs = try {
                DocumentFile.fromTreeUri(this, tree)?.listFiles()
            } catch (e: Exception) {
                null
            }
            docs?.forEach { doc ->
                val name = doc.name ?: return@forEach
                if (name.startsWith(".")) return@forEach
                val type = mediaTypeFor(name) ?: return@forEach
                if (doc.length() == 0L) return@forEach
                seen.putIfAbsent(name, mapOf(
                    "id" to md5(name),
                    "name" to name,
                    "path" to null,
                    "uri" to doc.uri.toString(),
                    "type" to type,
                    "modified" to doc.lastModified(),
                    "size" to doc.length(),
                ))
            }
        }

        return seen.values.sortedByDescending { it["modified"] as Long }
    }

    // ------------------------------------------------------------------
    // Runtime storage permission
    // ------------------------------------------------------------------

    private fun hasStoragePermission(): Boolean = storagePermissions.any {
        checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestStoragePermission(result: MethodChannel.Result) {
        if (hasStoragePermission()) {
            result.success(mapOf("granted" to true, "permanentlyDenied" to false))
            return
        }
        if (pendingPermissionResult != null) {
            result.error("busy", "A permission request is already in progress", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(storagePermissions, REQUEST_PERMISSION)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_PERMISSION) return
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        val granted = hasStoragePermission()
        val permanentlyDenied = !granted && storagePermissions.none {
            shouldShowRequestPermissionRationale(it)
        }
        result.success(mapOf("granted" to granted, "permanentlyDenied" to permanentlyDenied))
    }

    private fun openAppSettings(): Boolean = try {
        startActivity(
            Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
        )
        true
    } catch (e: ActivityNotFoundException) {
        false
    }

    // ------------------------------------------------------------------
    // Storage Access Framework
    // ------------------------------------------------------------------

    private fun prefs() = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun persistedSafTree(): Uri? {
        val stored = prefs().getString(KEY_SAF_URI, null) ?: return null
        val uri = Uri.parse(stored)
        val stillGranted = contentResolver.persistedUriPermissions.any {
            it.uri == uri && it.isReadPermission
        }
        return if (stillGranted) uri else null
    }

    private fun requestSafAccess(result: MethodChannel.Result) {
        if (pendingSafResult != null) {
            result.error("busy", "A folder access request is already in progress", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val statusesDocId = "primary:Android/media/$WHATSAPP/WhatsApp/Media/.Statuses"
                val initial = DocumentsContract.buildDocumentUri(
                    "com.android.externalstorage.documents", statusesDocId
                )
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, initial)
            }
        }
        try {
            pendingSafResult = result
            startActivityForResult(intent, REQUEST_SAF)
        } catch (e: ActivityNotFoundException) {
            pendingSafResult = null
            result.error("no_picker", "No document picker available on this device", null)
        }
    }

    @Deprecated("Deprecated in Android, still the supported path for FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_SAF) return
        val result = pendingSafResult ?: return
        pendingSafResult = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(false)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            prefs().edit().putString(KEY_SAF_URI, uri.toString()).apply()
            result.success(true)
        } catch (e: SecurityException) {
            result.success(false)
        }
    }

    private fun clearSafAccess(): Boolean {
        val stored = prefs().getString(KEY_SAF_URI, null) ?: return true
        try {
            contentResolver.releasePersistableUriPermission(
                Uri.parse(stored), Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (e: SecurityException) {
            // Grant was already revoked by the system; nothing to release.
        }
        prefs().edit().remove(KEY_SAF_URI).apply()
        return true
    }

    // ------------------------------------------------------------------
    // Thumbnails and playable files
    // ------------------------------------------------------------------

    private fun md5(input: String): String =
        MessageDigest.getInstance("MD5").digest(input.toByteArray())
            .joinToString("") { "%02x".format(it) }

    private fun openInput(path: String?, uri: String?): InputStream? = when {
        path != null -> File(path).inputStream()
        uri != null -> contentResolver.openInputStream(Uri.parse(uri))
        else -> null
    }

    /** Returns {"path": thumbPath, "duration": millis or null}. */
    private fun getThumbnail(path: String?, uri: String?, type: String, key: String): Map<String, Any?> {
        val thumbsDir = File(cacheDir, "thumbs").apply { mkdirs() }
        val thumbFile = File(thumbsDir, "${md5(key)}.jpg")
        val metaFile = File(thumbsDir, "${md5(key)}.meta")
        if (thumbFile.exists() && thumbFile.length() > 0) {
            val duration = metaFile.takeIf { it.exists() }?.readText()?.toLongOrNull()
            return mapOf("path" to thumbFile.absolutePath, "duration" to duration)
        }

        var duration: Long? = null
        val decoded: Bitmap? = if (type == "video") {
            val retriever = MediaMetadataRetriever()
            try {
                if (path != null) retriever.setDataSource(path)
                else retriever.setDataSource(this, Uri.parse(uri))
                duration = retriever
                    .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
                retriever.getFrameAtTime(1_000_000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    ?: retriever.getFrameAtTime(0)
            } finally {
                retriever.release()
            }
        } else {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            openInput(path, uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= THUMB_SIZE &&
                bounds.outHeight / (sample * 2) >= THUMB_SIZE
            ) sample *= 2
            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            openInput(path, uri)?.use { BitmapFactory.decodeStream(it, null, opts) }
        }
        val bitmap = decoded
            ?: throw IllegalStateException("Could not decode media for thumbnail")

        val scaled = scaleDown(bitmap, THUMB_SIZE)
        FileOutputStream(thumbFile).use { scaled.compress(Bitmap.CompressFormat.JPEG, 82, it) }
        if (scaled != bitmap) bitmap.recycle()
        duration?.let { metaFile.writeText(it.toString()) }
        return mapOf("path" to thumbFile.absolutePath, "duration" to duration)
    }

    private fun scaleDown(src: Bitmap, max: Int): Bitmap {
        val largest = maxOf(src.width, src.height)
        if (largest <= max) return src
        val ratio = max.toFloat() / largest
        return Bitmap.createScaledBitmap(
            src, (src.width * ratio).toInt().coerceAtLeast(1),
            (src.height * ratio).toInt().coerceAtLeast(1), true
        )
    }

    /**
     * Guarantees a readable local file for the given media. Direct paths are
     * returned as-is; SAF content URIs are copied once into the cache.
     */
    private fun getPlayableFile(path: String?, uri: String?, name: String): String {
        if (path != null) return path
        requireNotNull(uri) { "Either path or uri is required" }
        val mediaDir = File(cacheDir, "media").apply { mkdirs() }
        val safeName = name.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val target = File(mediaDir, safeName)
        if (!target.exists() || target.length() == 0L) {
            contentResolver.openInputStream(Uri.parse(uri)).use { input ->
                requireNotNull(input) { "Cannot open source media" }
                FileOutputStream(target).use { output -> input.copyTo(output) }
            }
        }
        return target.absolutePath
    }

    // ------------------------------------------------------------------
    // Saving to the gallery (MediaStore)
    // ------------------------------------------------------------------

    private fun mimeFor(name: String, type: String): String {
        val ext = name.substringAfterLast('.', "").lowercase()
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
            ?: if (type == "video") "video/mp4" else "image/jpeg"
    }

    private fun savedName(originalName: String): String =
        SAVE_PREFIX + originalName.replace(Regex("[^A-Za-z0-9._-]"), "_")

    private fun collectionFor(type: String): Uri =
        if (type == "video") MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        else MediaStore.Images.Media.EXTERNAL_CONTENT_URI

    private fun findSaved(displayName: String, type: String): Uri? {
        val collection = collectionFor(type)
        val idColumn = MediaStore.MediaColumns._ID
        contentResolver.query(
            collection, arrayOf(idColumn),
            "${MediaStore.MediaColumns.DISPLAY_NAME} = ?", arrayOf(displayName), null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return ContentUris.withAppendedId(collection, cursor.getLong(0))
            }
        }
        return null
    }

    /** Returns {"status": "saved"|"exists", "uri": string}. */
    private fun saveToGallery(path: String?, uri: String?, name: String, type: String): Map<String, Any?> {
        val displayName = savedName(name)
        findSaved(displayName, type)?.let {
            return mapOf("status" to "exists", "uri" to it.toString())
        }

        val input = openInput(path, uri)
            ?: throw IllegalStateException("The status file is no longer available")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val relativeDir =
                if (type == "video") "${Environment.DIRECTORY_MOVIES}/$SAVE_DIR"
                else "${Environment.DIRECTORY_PICTURES}/$SAVE_DIR"
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeFor(name, type))
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativeDir)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val collection = collectionFor(type)
            val itemUri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("Could not create the destination file")
            try {
                contentResolver.openOutputStream(itemUri).use { output ->
                    requireNotNull(output) { "Could not open the destination file" }
                    input.use { it.copyTo(output) }
                }
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(itemUri, values, null, null)
            } catch (e: Exception) {
                contentResolver.delete(itemUri, null, null)
                throw e
            }
            return mapOf("status" to "saved", "uri" to itemUri.toString())
        } else {
            val baseDir = Environment.getExternalStoragePublicDirectory(
                if (type == "video") Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
            )
            val dir = File(baseDir, SAVE_DIR).apply { mkdirs() }
            val target = File(dir, displayName)
            input.use { src -> FileOutputStream(target).use { src.copyTo(it) } }
            MediaScannerConnection.scanFile(this, arrayOf(target.absolutePath), null, null)
            return mapOf("status" to "saved", "uri" to Uri.fromFile(target).toString())
        }
    }

    // ------------------------------------------------------------------
    // Saved gallery listing / deleting
    // ------------------------------------------------------------------

    private fun listSaved(): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        for (type in listOf("image", "video")) {
            val collection = collectionFor(type)
            val projection = arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.DATE_MODIFIED,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATA,
            )
            val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
            val selectionArgs = arrayOf("$SAVE_PREFIX%")
            try {
                contentResolver.query(collection, projection, selection, selectionArgs, null)
                    ?.use { cursor ->
                        val idIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                        val nameIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
                        val dateIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
                        val sizeIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                        val dataIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                        while (cursor.moveToNext()) {
                            val id = cursor.getLong(idIdx)
                            val name = cursor.getString(nameIdx) ?: continue
                            results.add(mapOf(
                                "id" to md5("saved_$name"),
                                "name" to name,
                                "path" to cursor.getString(dataIdx),
                                "uri" to ContentUris.withAppendedId(collection, id).toString(),
                                "type" to type,
                                "modified" to cursor.getLong(dateIdx) * 1000,
                                "size" to cursor.getLong(sizeIdx),
                            ))
                        }
                    }
            } catch (e: SecurityException) {
                // Without media permission we can still see rows this app owns.
            }
        }
        return results.sortedByDescending { it["modified"] as Long }
    }

    private fun deleteSaved(uriString: String?): Boolean {
        val uri = Uri.parse(uriString ?: return false)
        return try {
            if ("file" == uri.scheme) {
                val file = File(uri.path ?: return false)
                val deleted = file.delete()
                if (deleted) MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), null, null)
                deleted
            } else {
                contentResolver.delete(uri, null, null) > 0
            }
        } catch (e: SecurityException) {
            false
        }
    }

    // ------------------------------------------------------------------
    // Sharing / opening
    // ------------------------------------------------------------------

    private fun shareableUri(path: String?, uri: String?): Uri? = when {
        uri != null && Uri.parse(uri).scheme == "content" -> Uri.parse(uri)
        path != null -> FileProvider.getUriForFile(
            this, "$packageName.fileprovider", File(path)
        )
        uri != null && Uri.parse(uri).scheme == "file" -> FileProvider.getUriForFile(
            this, "$packageName.fileprovider", File(Uri.parse(uri).path!!)
        )
        else -> null
    }

    /** Returns "ok", "not_installed", "no_app" or "error". */
    private fun shareMedia(
        path: String?, uri: String?, mime: String, targetPackage: String?, title: String
    ): String {
        val contentUri = shareableUri(path, uri) ?: return "error"
        val send = Intent(Intent.ACTION_SEND).apply {
            this.type = mime
            putExtra(Intent.EXTRA_STREAM, contentUri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            if (targetPackage != null) {
                val installed = listOf(targetPackage, WHATSAPP_BUSINESS)
                    .firstOrNull { isInstalled(it) }
                    ?: return "not_installed"
                send.setPackage(installed)
                startActivity(send)
            } else {
                startActivity(Intent.createChooser(send, title))
            }
            "ok"
        } catch (e: ActivityNotFoundException) {
            "no_app"
        } catch (e: Exception) {
            "error"
        }
    }

    private fun openMedia(path: String?, uri: String?, mime: String): String {
        val contentUri = shareableUri(path, uri) ?: return "error"
        val view = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(contentUri, mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            startActivity(view)
            "ok"
        } catch (e: ActivityNotFoundException) {
            "no_app"
        }
    }
}
