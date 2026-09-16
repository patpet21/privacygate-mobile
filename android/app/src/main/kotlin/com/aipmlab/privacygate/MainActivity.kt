package com.aipmlab.privacygate

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val vaultChannelName = "com.aipmlab.privacygate/vault"
    private val vaultKeyAlias = "privacygate_mobile_vault_v1"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            vaultChannelName,
        ).setMethodCallHandler { call, result ->
            handleVaultCall(call, result)
        }
    }

    private fun handleVaultCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "vaultDirectoryPath" -> {
                    val directory = File(filesDir, "Vault")
                    if (!directory.exists() && !directory.mkdirs()) {
                        throw IllegalStateException("Unable to create Vault directory")
                    }
                    result.success(directory.absolutePath)
                }

                "libraryDirectoryPath" -> {
                    val directory = File(filesDir, "Library")
                    if (!directory.exists() && !directory.mkdirs()) {
                        throw IllegalStateException("Unable to create Library directory")
                    }
                    result.success(directory.absolutePath)
                }

                "encrypt" -> {
                    val clearText = call.argument<ByteArray>("clearText")
                        ?: throw IllegalArgumentException("Missing clearText")
                    val aad = call.argument<ByteArray>("aad") ?: byteArrayOf()
                    val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                    cipher.init(Cipher.ENCRYPT_MODE, getOrCreateVaultKey())
                    cipher.updateAAD(aad)
                    val cipherText = cipher.doFinal(clearText)
                    result.success(
                        mapOf(
                            "nonce" to cipher.iv,
                            "cipherText" to cipherText,
                        ),
                    )
                }

                "decrypt" -> {
                    val nonce = call.argument<ByteArray>("nonce")
                        ?: throw IllegalArgumentException("Missing nonce")
                    val cipherText = call.argument<ByteArray>("cipherText")
                        ?: throw IllegalArgumentException("Missing cipherText")
                    val aad = call.argument<ByteArray>("aad") ?: byteArrayOf()
                    val key = existingVaultKey()
                    if (key == null) {
                        result.error(
                            "vault_auth_failed",
                            "Encrypted Vault key is unavailable",
                            null,
                        )
                        return
                    }
                    try {
                        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                        cipher.init(
                            Cipher.DECRYPT_MODE,
                            key,
                            GCMParameterSpec(128, nonce),
                        )
                        cipher.updateAAD(aad)
                        result.success(cipher.doFinal(cipherText))
                    } catch (_: AEADBadTagException) {
                        result.error(
                            "vault_auth_failed",
                            "Encrypted Vault authentication failed",
                            null,
                        )
                    }
                }

                "deleteKey" -> {
                    val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
                    if (keyStore.containsAlias(vaultKeyAlias)) {
                        keyStore.deleteEntry(vaultKeyAlias)
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("vault_error", error.message ?: "Vault operation failed", null)
        }
    }

    private fun existingVaultKey(): SecretKey? {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        return keyStore.getKey(vaultKeyAlias, null) as? SecretKey
    }

    private fun getOrCreateVaultKey(): SecretKey {
        existingVaultKey()?.let { return it }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore",
        )
        keyGenerator.init(
            KeyGenParameterSpec.Builder(
                vaultKeyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return keyGenerator.generateKey()
    }
}
