import CryptoKit
import Flutter
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let vaultChannelName = "com.aipmlab.privacygate/vault"
  private let vaultKeyService = "com.aipmlab.privacygate.vault"
  private let vaultKeyAccount = "master-key-v1"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let vaultChannel = FlutterMethodChannel(
      name: vaultChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    vaultChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleVaultCall(call, result: result)
    }
  }

  private func handleVaultCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "vaultDirectoryPath":
        result(try vaultDirectory().path)

      case "encrypt":
        guard
          let arguments = call.arguments as? [String: Any],
          let clearText = data(from: arguments["clearText"]),
          let aad = data(from: arguments["aad"])
        else {
          throw VaultError.invalidArguments
        }
        let sealedBox = try AES.GCM.seal(
          clearText,
          using: try getOrCreateVaultKey(),
          authenticating: aad
        )
        let nonce = sealedBox.nonce.withUnsafeBytes { Data($0) }
        var cipherText = Data(sealedBox.ciphertext)
        cipherText.append(sealedBox.tag)
        result([
          "nonce": FlutterStandardTypedData(bytes: nonce),
          "cipherText": FlutterStandardTypedData(bytes: cipherText),
        ])

      case "decrypt":
        guard
          let arguments = call.arguments as? [String: Any],
          let nonceData = data(from: arguments["nonce"]),
          let cipherAndTag = data(from: arguments["cipherText"]),
          let aad = data(from: arguments["aad"]),
          cipherAndTag.count >= 16
        else {
          throw VaultError.invalidArguments
        }
        guard let key = try existingVaultKey() else {
          result(
            FlutterError(
              code: "vault_auth_failed",
              message: "Encrypted Vault key is unavailable",
              details: nil
            )
          )
          return
        }
        do {
          let nonce = try AES.GCM.Nonce(data: nonceData)
          let tagStart = cipherAndTag.count - 16
          let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: Data(cipherAndTag.prefix(tagStart)),
            tag: Data(cipherAndTag.suffix(16))
          )
          let clearText = try AES.GCM.open(
            sealedBox,
            using: key,
            authenticating: aad
          )
          result(FlutterStandardTypedData(bytes: clearText))
        } catch {
          result(
            FlutterError(
              code: "vault_auth_failed",
              message: "Encrypted Vault authentication failed",
              details: nil
            )
          )
        }

      case "deleteKey":
        try deleteVaultKey()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(
        FlutterError(
          code: "vault_error",
          message: String(describing: error),
          details: nil
        )
      )
    }
  }

  private func vaultDirectory() throws -> URL {
    guard let applicationSupport = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first else {
      throw VaultError.directoryUnavailable
    }
    var directory = applicationSupport
      .appendingPathComponent("PrivacyGate", isDirectory: true)
      .appendingPathComponent("Vault", isDirectory: true)
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true,
      attributes: [.protectionKey: FileProtectionType.complete]
    )
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try directory.setResourceValues(values)
    return directory
  }

  private func existingVaultKey() throws -> SymmetricKey? {
    guard let data = try readVaultKey() else { return nil }
    return SymmetricKey(data: data)
  }

  private func getOrCreateVaultKey() throws -> SymmetricKey {
    if let existing = try existingVaultKey() {
      return existing
    }

    var bytes = [UInt8](repeating: 0, count: 32)
    guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
      throw VaultError.randomGenerationFailed
    }
    let keyData = Data(bytes)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: vaultKeyService,
      kSecAttrAccount as String: vaultKeyAccount,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      kSecValueData as String: keyData,
    ]
    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecDuplicateItem, let existing = try existingVaultKey() {
      return existing
    }
    guard status == errSecSuccess else {
      throw VaultError.keychain(status)
    }
    return SymmetricKey(data: keyData)
  }

  private func readVaultKey() throws -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: vaultKeyService,
      kSecAttrAccount as String: vaultKeyAccount,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess, let data = item as? Data, data.count == 32 else {
      throw VaultError.keychain(status)
    }
    return data
  }

  private func deleteVaultKey() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: vaultKeyService,
      kSecAttrAccount as String: vaultKeyAccount,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw VaultError.keychain(status)
    }
  }

  private func data(from value: Any?) -> Data? {
    if let typedData = value as? FlutterStandardTypedData {
      return typedData.data
    }
    if let data = value as? Data {
      return data
    }
    return nil
  }
}

private enum VaultError: Error, CustomStringConvertible {
  case invalidArguments
  case directoryUnavailable
  case randomGenerationFailed
  case keychain(OSStatus)

  var description: String {
    switch self {
    case .invalidArguments:
      return "Invalid Vault arguments"
    case .directoryUnavailable:
      return "Vault directory is unavailable"
    case .randomGenerationFailed:
      return "Unable to generate Vault key material"
    case .keychain(let status):
      return "Keychain error: \(status)"
    }
  }
}
