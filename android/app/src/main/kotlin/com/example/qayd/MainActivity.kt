package com.example.qayd

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "app.qayd/whatsapp_intent"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPackageInstalled" -> {
                    val packageName = call.argument<String>("packageName") ?: return@setMethodCallHandler result.error("INVALID_ARGS", "Package name required", null)
                    result.success(isPackageInstalled(packageName))
                }
                "shareToWhatsApp" -> {
                    val packageName = call.argument<String>("packageName") ?: "com.whatsapp"
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    val filePath = call.argument<String>("filePath")
                    
                    if (!isPackageInstalled(packageName)) {
                        result.error("APP_NOT_INSTALLED", "Target application is not installed.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val intent = Intent(Intent.ACTION_SEND)
                        val mimeType = if (filePath != null) {
                            val file = File(filePath)
                            when (file.extension.lowercase()) {
                                "pdf" -> "application/pdf"
                                "png" -> "image/png"
                                "jpg", "jpeg" -> "image/jpeg"
                                "webp" -> "image/webp"
                                else -> "*/*"
                            }
                        } else {
                            "text/plain"
                        }
                        intent.type = mimeType
                        intent.setPackage(packageName)
                        
                        // Set text message
                        if (!message.isNullOrBlank()) {
                            intent.putExtra(Intent.EXTRA_TEXT, message)
                        }

                        // Attach specific contact (JID)
                        if (!phoneNumber.isNullOrBlank()) {
                            // Format: Number must include country code, NO '+' sign. Example: 1234567890
                            val cleanNumber = phoneNumber.replace(Regex("[^0-9]"), "")
                            intent.putExtra("jid", "$cleanNumber@s.whatsapp.net")
                        }

                        // Attach File via FileProvider
                        if (!filePath.isNullOrBlank()) {
                            val file = File(filePath)
                            if (file.exists()) {
                                val uri: Uri = FileProvider.getUriForFile(
                                    this, 
                                    "${this.packageName}.fileprovider", 
                                    file
                                )
                                intent.putExtra(Intent.EXTRA_STREAM, uri)
                                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                        }

                        // Start activity without chooser
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
