//
//  ZaprySecurityStore.swift
//  MIMO
//
//  Created by jazohuang on 2024/3/5.
//

import Foundation
import Security
import LocalAuthentication
import CryptoSwift

@objcMembers public class ZaprySecurityStore : NSObject {
    
    ///
    /// 安全的生物识别验证的钱包
    ///
    /// 仅本地存储，不会同步至iCloud
    /// 需要通过FaceID、TouchID、开机密码其中一个才能读。至于写，首次写无需要，覆盖写需要。一旦手机丢失，将无法找回。
    ///
    private static let biometric_wallet_item = "biometric.web3wallet.zapry.net"
    static func setWalletThatAuthByBiometric(walletInfo: String) -> Bool {
        let uid = ZapryPrivateKeyHelper.shared.getUserIdFromOptions()
        if ( uid.count <= 0 || walletInfo.count <= 0 ) { return false }
        guard let data = ZaprySecurityStore.biometricEncode(walletInfo: walletInfo, key: ZaprySecurityStore.randomPassword(length: 64)) else { return false }
        guard let query = ZaprySecurityStore.biometricSetDic(uid: uid, server: ZaprySecurityStore.biometric_wallet_item, data: data) else { return false }
        return ZaprySecurityStore.setSSItem(query: query)
    }
    static func getWalletThatAuthByBiometric() -> String? {
        let uid = ZapryPrivateKeyHelper.shared.getUserIdFromOptions()
        if ( uid.count <= 0 ) { return nil }
        let query = ZaprySecurityStore.biometricGetDic(uid: uid, server: ZaprySecurityStore.biometric_wallet_item)
        if let data = ZaprySecurityStore.getSSItem(query: query) {
            return ZaprySecurityStore.biometricDecode(data: data)
        }
        return nil
    }
    static func deleteWalletThatAuthByBiometric() -> Bool {
        let uid = ZapryPrivateKeyHelper.shared.getUserIdFromOptions()
        if ( uid.count <= 0 ) { return false }
        let query = ZaprySecurityStore.biometricGetDic(uid: uid, server: ZaprySecurityStore.biometric_wallet_item)
        return ZaprySecurityStore.deleteSSItem(query: query)
    }
    private static func biometricEncode(walletInfo: String, key: String) -> Data? {
        if ( key.count <= 0 ) { return nil }
        guard let WK = ZaprySecurityStore.encrypt(value: walletInfo, key: key) else { return nil }
        let RK = key
        let item = "\(RK)|\(WK)" // 其实这里的RK和encrypt不是必要的，仅仅提高了一点点门槛
        guard let data = item.data(using: .utf8) else { return nil }
        return data
    }
    private static func biometricDecode(data: Data) -> String? {
        guard let s = String(data: data, encoding: .utf8) else { return nil }
        let cs = s.components(separatedBy: "|")
        if ( cs.count != 2 ) { return nil }
        let key = cs[0]
        let value = cs[1]
        return ZaprySecurityStore.decrypt(encryptValue: value, key: key)
    }
    private static func randomPassword(length: Int) -> String {
        var bytes = Data(count: length)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!) }
        return bytes.base64EncodedString()
    }
    private static func biometricItemAccess() -> SecAccessControl? {
        let allocator: CFAllocator! = kCFAllocatorDefault
        let flags: SecAccessControlCreateFlags = SecAccessControlCreateFlags.userPresence
        let protection: AnyObject = kSecAttrAccessibleWhenUnlockedThisDeviceOnly // 注意：如果开机密码被删除，需要上层业务入口控制好
        var accessControlError: Unmanaged<CFError>?
        let access = SecAccessControlCreateWithFlags(
            allocator,
            protection,
            flags,
            &accessControlError
        )
        return access
    }
    private static func biometricSetDic(uid: String, server: String, data: Data) -> Dictionary<String,Any>? {
        guard let access = ZaprySecurityStore.biometricItemAccess() else { return nil }
        let context = LAContext()
        context.localizedReason = "Access your password on the keychain"
        return [kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: uid,
                kSecAttrServer as String: server,
                kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
                
                kSecAttrAccessControl as String: access as Any,
                kSecUseAuthenticationContext as String: context,
                kSecValueData as String: data,
        ]
    }
    private static func biometricGetDic(uid: String, server: String) -> Dictionary<String,Any> {
        return [kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: uid,
                kSecAttrServer as String: server,
                kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
                
                kSecReturnData as String: true
        ]
    }
    
    ///
    /// 支付密码验证的钱包
    ///
    /// 仅本地存储，不会同步至iCloud
    /// 读和写都需要有支付密码，密码仅存MD5，仅用于身份验证，原始密码仅记在用户大脑中，一旦遗忘或手机丢失，将无法找回
    ///
    private static let pay_password_wallet_item = "pay.web3wallet.zapry.net"
    static func setWalletThatAuthByPayPassword(walletInfo: String, payPassword: String) -> Bool {
        let uid = ZapryPrivateKeyHelper.shared.getUserIdFromOptions()
        if ( uid.count <= 0 || walletInfo.count <= 0 || payPassword.count < 6 ) { return false }
        guard let data = ZaprySecurityStore.payPasswordEncode(walletInfo: walletInfo, payPassword: payPassword) else { return false }
        guard let query = ZaprySecurityStore.payPasswordSetDic(uid: uid, server: ZaprySecurityStore.pay_password_wallet_item, data: data) else { return false }
        return ZaprySecurityStore.setSSItem(query: query)
    }
    static func getWalletThatAuthByPayPassword(payPassword: String) -> String? {
        let uid = ZapryPrivateKeyHelper.shared.getUserIdFromOptions()
        if ( uid.count <= 0 || payPassword.count < 6 ) { return nil }
        let query = ZaprySecurityStore.payPasswordGetDic(uid: uid, server: ZaprySecurityStore.pay_password_wallet_item)
        if let data = ZaprySecurityStore.getSSItem(query: query) {
            return ZaprySecurityStore.payPasswordDecode(data: data, payPassword: payPassword)
        }
        return nil
    }
    static func hasWalletThatAuthByPayPassword() -> Bool {
        let uid = ZapryPrivateKeyHelper.shared.getUserIdFromOptions()
        if ( uid.count <= 0 ) { return false }
        let query = ZaprySecurityStore.payPasswordGetDic(uid: uid, server: ZaprySecurityStore.pay_password_wallet_item)
        if let data = ZaprySecurityStore.getSSItem(query: query) {
            return true
        }
        return false
    }
    static func deleteWalletThatAuthByPayPassword() -> Bool {
        let uid = ZapryPrivateKeyHelper.shared.getUserIdFromOptions()
        if ( uid.count <= 0 ) { return false }
        let query = ZaprySecurityStore.payPasswordGetDic(uid: uid, server: ZaprySecurityStore.pay_password_wallet_item)
        return ZaprySecurityStore.deleteSSItem(query: query)
    }
    private static func payPasswordEncode(walletInfo: String, payPassword: String) -> Data? {
        if ( payPassword.count <= 0 ) { return nil }
        guard let WK = ZaprySecurityStore.encrypt(value: walletInfo, key: payPassword) else { return nil }
        let IK = payPassword.md5
        let item = "\(IK)|\(WK)"
        guard let data = item.data(using: .utf8) else { return nil }
        return data
    }
    private static func payPasswordDecode(data: Data, payPassword: String) -> String? {
        guard let s = String(data: data, encoding: .utf8) else { return nil }
        let cs = s.components(separatedBy: "|")
        if ( cs.count != 2 ) { return nil }
        let IK = cs[0]
        let WK = cs[1]
        if ( payPassword.md5() != IK ) { return nil } // 身份验证不通过
        return ZaprySecurityStore.decrypt(encryptValue: WK, key: payPassword)
    }
    private static func payPasswordSetDic(uid: String, server: String, data: Data) -> Dictionary<String,Any>? {
        return [kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: uid,
                kSecAttrServer as String: server,
                kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
                
                kSecValueData as String: data,
        ]
    }
    private static func payPasswordGetDic(uid: String, server: String) -> Dictionary<String,Any> {
        return [kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: uid,
                kSecAttrServer as String: server,
                kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
                
                kSecReturnData as String: true
        ]
    }

    ///
    /// 备份密码验证的钱包
    ///
    /// 会同步至iCloud
    /// 读和写需要备份密码。每一次备份的密码可以不一样，密码不会存储，完全记在用户的大脑中，一旦遗忘或iCloud帐号丢失，将无法找回
    ///
    private static let backup_password_wallet_item = "backup.web3wallet.zapry.net"
    private static let backup_accout = "backup_accout"
    static func saveWalletThatAuthByBackupPassword(walletInfo: String, backupPassword: String) -> String? {
        if ( walletInfo.count <= 0 || backupPassword.count < 6 ) { return nil }
        let date = Date.init(timeIntervalSinceNow: 0).timeIntervalSince1970
        let timeString = String.init(format: "%.f", date)
        let backupID = "\(timeString).\(ZaprySecurityStore.backup_password_wallet_item)"
        guard let data = ZaprySecurityStore.backupEncode(walletInfo: walletInfo, backupPassword: backupPassword) else { return nil }
        guard let query = ZaprySecurityStore.backupSetDic(server: backupID, data: data) else { return nil }
        if ( ZaprySecurityStore.setSSItem(query: query) ) {
            return backupID
        }
        return nil
    }
    static func getWalletThatAuthByBackupPassword(backupID: String, backupPassword: String) throws -> String {
        let query = ZaprySecurityStore.backupGetDic(server: backupID)
        guard let data = ZaprySecurityStore.getSSItem(query: query) else {
            throw MMSecurityStoreError.queryError
        }
        if let WK = String(data: data, encoding: .utf8) {
            return try ZaprySecurityStore.decryptWithThrows(encryptValue: WK, key: backupPassword)
        } else {
            throw MMSecurityStoreError.encodeError
        }
    }
    static func deleteWalletThatAuthByBackupPassword(backupID: String) -> Bool {
        let query = ZaprySecurityStore.backupGetDic(server: backupID)
        return ZaprySecurityStore.deleteSSItem(query: query)
    }
    static func getUndecryptWalletsThatAuthByBackupPassword() -> Dictionary<String,String> {
        var ret = Dictionary<String,String>()
        let query = ZaprySecurityStore.backupAllGetDic()
        guard let array = ZaprySecurityStore.getSSItems(query: query) else { return ret }
        for item in array {
            if let server = item[kSecAttrServer as String] as? String {
                if ( server.hasSuffix(ZaprySecurityStore.backup_password_wallet_item) ) {
                    if let data = item[kSecValueData as String] as? Data {
                        if let WK = String(data: data, encoding: .utf8) {
                            ret[server] = WK
                        }
                    }
                }
            }
        }
        return ret
    }
    private static func backupEncode(walletInfo: String, backupPassword: String) -> Data? {
        if ( backupPassword.count < 6 ) { return nil }
        guard let WK = ZaprySecurityStore.encrypt(value: walletInfo, key: backupPassword) else { return nil }
        return WK.data(using: .utf8)
    }
    private static func backupSetDic(server: String, data: Data) -> Dictionary<String,Any>? {
        return [kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: ZaprySecurityStore.backup_accout,
                kSecAttrServer as String: server,
                kSecAttrSynchronizable as String: kCFBooleanTrue as Any,
                
                kSecValueData as String: data,
        ]
    }
    private static func backupGetDic(server: String) -> Dictionary<String,Any> {
        return [kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: ZaprySecurityStore.backup_accout,
                kSecAttrServer as String: server,
                kSecAttrSynchronizable as String: kCFBooleanTrue as Any,
                
                kSecReturnData as String: true
        ]
    }
    private static func backupAllGetDic() -> Dictionary<String,Any> {
        return [kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: ZaprySecurityStore.backup_accout,
                kSecAttrSynchronizable as String: kCFBooleanTrue as Any,
                
                kSecReturnData as String: true,
                kSecReturnAttributes as String: true,
                kSecReturnRef as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll
        ]
    }
    
    
    // 通用方法
    private static func setSSItem(query: Dictionary<String,Any>) -> Bool {
        var status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem { // 更新
            if let data = query[kSecValueData as String] {
                let att: Dictionary<String,Any> = [kSecValueData as String: data]
                status = SecItemUpdate(query as CFDictionary, att as CFDictionary)
            }
        }
        if status != errSecSuccess {
            return false
        }
        return true
    }
    
    private static func getSSItem(query: Dictionary<String,Any>) -> Data? {
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status != errSecSuccess {
            return nil
        }
        if let r = (result as? Data) {
            return r
        }
        return nil
    }
    
    private static func getSSItems(query: Dictionary<String,Any>) -> Array<Dictionary<String,Any>>? {
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status != errSecSuccess {
            return nil
        }
        if let r = ( result as? Array<Dictionary<String,Any>> ) {
            return r
        }
        return nil
    }
    
    private static func deleteSSItem(query: Dictionary<String,Any>) -> Bool {
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            return false
        }
        return true
    }
    
    private static func getAES(r: String) -> CryptoSwift.AES? {
        let md5Str = r.md5().md5()
        let key = String(md5Str.prefix(12)) + "MIMO"
        let iv = String(md5Str.suffix(12)) + "MIMO"
        let aes = try? CryptoSwift.AES(key: key, iv: iv)
        return aes
    }
    
    static func encrypt(value: String, key: String) -> String? {
        guard let aes = getAES(r: key) else { return nil }
        guard let result = try? aes.encrypt(value.bytes) else { return nil }
        return result.toBase64()
    }
    
    static func decrypt(encryptValue: String, key: String) -> String? {
        guard let aes = getAES(r: key) else { return nil }
        guard let result = try? encryptValue.decryptBase64(cipher: aes) else { return nil }
        return String(data: Data(result), encoding: .utf8)
    }
    
    static func decryptWithThrows(encryptValue: String, key: String) throws -> String {
        guard let aes = getAES(r: key) else { throw MMSecurityStoreError.getAESError }
        guard let result = try? encryptValue.decryptBase64(cipher: aes) else { throw MMSecurityStoreError.decryptError }
        if let ret = String(data: Data(result), encoding: .utf8) {
            return ret
        } else {
            throw MMSecurityStoreError.encodeError
        }
    }
}

public enum MMSecurityStoreError: Error {
    case getAESError
    case decryptError
    case queryError
    case encodeError
    case decodeError
}


/**
 
 CF_ENUM(OSStatus)
 {
     errSecSuccess                            = 0,       /* No error. */
     errSecUnimplemented                      = -4,      /* Function or operation not implemented. */
     errSecDiskFull                           = -34,     /* The disk is full. */
     errSecDskFull                            = -34,
     errSecIO                                 = -36,     /* I/O error. */
     errSecOpWr                               = -49,     /* File already open with write permission. */
     errSecParam                              = -50,     /* One or more parameters passed to a function were not valid. */
     errSecWrPerm                             = -61,     /* Write permissions error. */
     errSecAllocate                           = -108,    /* Failed to allocate memory. */
     errSecUserCanceled                       = -128,    /* User canceled the operation. */
     errSecBadReq                             = -909,    /* Bad parameter or invalid state for operation. */
  
     errSecInternalComponent                  = -2070,
     errSecCoreFoundationUnknown              = -4960,
  
     errSecMissingEntitlement                 = -34018,    /* A required entitlement isn't present. */
  
     errSecNotAvailable                       = -25291,    /* No keychain is available. You may need to restart your computer. */
     errSecReadOnly                           = -25292,    /* This keychain cannot be modified. */
     errSecAuthFailed                         = -25293,    /* The user name or passphrase you entered is not correct. */
     errSecNoSuchKeychain                     = -25294,    /* The specified keychain could not be found. */
     errSecInvalidKeychain                    = -25295,    /* The specified keychain is not a valid keychain file. */
     errSecDuplicateKeychain                  = -25296,    /* A keychain with the same name already exists. */
     errSecDuplicateCallback                  = -25297,    /* The specified callback function is already installed. */
     errSecInvalidCallback                    = -25298,    /* The specified callback function is not valid. */
     errSecDuplicateItem                      = -25299,    /* The specified item already exists in the keychain. */
     errSecItemNotFound                       = -25300,    /* The specified item could not be found in the keychain. */
     errSecBufferTooSmall                     = -25301,    /* There is not enough memory available to use the specified item. */
     errSecDataTooLarge                       = -25302,    /* This item contains information which is too large or in a format that cannot be displayed. */
     errSecNoSuchAttr                         = -25303,    /* The specified attribute does not exist. */
     errSecInvalidItemRef                     = -25304,    /* The specified item is no longer valid. It may have been deleted from the keychain. */
     errSecInvalidSearchRef                   = -25305,    /* Unable to search the current keychain. */
     errSecNoSuchClass                        = -25306,    /* The specified item does not appear to be a valid keychain item. */
     errSecNoDefaultKeychain                  = -25307,    /* A default keychain could not be found. */
     errSecInteractionNotAllowed              = -25308,    /* User interaction is not allowed. */
     errSecReadOnlyAttr                       = -25309,    /* The specified attribute could not be modified. */
     errSecWrongSecVersion                    = -25310,    /* This keychain was created by a different version of the system software and cannot be opened. */
     errSecKeySizeNotAllowed                  = -25311,    /* This item specifies a key size which is too large or too small. */
     errSecNoStorageModule                    = -25312,    /* A required component (data storage module) could not be loaded. You may need to restart your computer. */
     errSecNoCertificateModule                = -25313,    /* A required component (certificate module) could not be loaded. You may need to restart your computer. */
     errSecNoPolicyModule                     = -25314,    /* A required component (policy module) could not be loaded. You may need to restart your computer. */
     errSecInteractionRequired                = -25315,    /* User interaction is required, but is currently not allowed. */
     errSecDataNotAvailable                   = -25316,    /* The contents of this item cannot be retrieved. */
     errSecDataNotModifiable                  = -25317,    /* The contents of this item cannot be modified. */
     errSecCreateChainFailed                  = -25318,    /* One or more certificates required to validate this certificate cannot be found. */
     errSecInvalidPrefsDomain                 = -25319,    /* The specified preferences domain is not valid. */
     errSecInDarkWake                         = -25320,    /* In dark wake, no UI possible */
  
     errSecACLNotSimple                       = -25240,    /* The specified access control list is not in standard (simple) form. */
     errSecPolicyNotFound                     = -25241,    /* The specified policy cannot be found. */
     errSecInvalidTrustSetting                = -25242,    /* The specified trust setting is invalid. */
     errSecNoAccessForItem                    = -25243,    /* The specified item has no access control. */
     errSecInvalidOwnerEdit                   = -25244,    /* Invalid attempt to change the owner of this item. */
     errSecTrustNotAvailable                  = -25245,    /* No trust results are available. */
     errSecUnsupportedFormat                  = -25256,    /* Import/Export format unsupported. */
     errSecUnknownFormat                      = -25257,    /* Unknown format in import. */
     errSecKeyIsSensitive                     = -25258,    /* Key material must be wrapped for export. */
     errSecMultiplePrivKeys                   = -25259,    /* An attempt was made to import multiple private keys. */
     errSecPassphraseRequired                 = -25260,    /* Passphrase is required for import/export. */
     errSecInvalidPasswordRef                 = -25261,    /* The password reference was invalid. */
     errSecInvalidTrustSettings               = -25262,    /* The Trust Settings Record was corrupted. */
     errSecNoTrustSettings                    = -25263,    /* No Trust Settings were found. */
     errSecPkcs12VerifyFailure                = -25264,    /* MAC verification failed during PKCS12 import (wrong password?) */
     errSecNotSigner                          = -26267,    /* A certificate was not signed by its proposed parent. */
  
     errSecDecode                             = -26275,    /* Unable to decode the provided data. */
  
     errSecServiceNotAvailable                = -67585,    /* The required service is not available. */
     errSecInsufficientClientID               = -67586,    /* The client ID is not correct. */
     errSecDeviceReset                        = -67587,    /* A device reset has occurred. */
     errSecDeviceFailed                       = -67588,    /* A device failure has occurred. */
     errSecAppleAddAppACLSubject              = -67589,    /* Adding an application ACL subject failed. */
     errSecApplePublicKeyIncomplete           = -67590,    /* The public key is incomplete. */
     errSecAppleSignatureMismatch             = -67591,    /* A signature mismatch has occurred. */
     errSecAppleInvalidKeyStartDate           = -67592,    /* The specified key has an invalid start date. */
     errSecAppleInvalidKeyEndDate             = -67593,    /* The specified key has an invalid end date. */
     errSecConversionError                    = -67594,    /* A conversion error has occurred. */
     errSecAppleSSLv2Rollback                 = -67595,    /* A SSLv2 rollback error has occurred. */
     errSecQuotaExceeded                      = -67596,    /* The quota was exceeded. */
     errSecFileTooBig                         = -67597,    /* The file is too big. */
     errSecInvalidDatabaseBlob                = -67598,    /* The specified database has an invalid blob. */
     errSecInvalidKeyBlob                     = -67599,    /* The specified database has an invalid key blob. */
     errSecIncompatibleDatabaseBlob           = -67600,    /* The specified database has an incompatible blob. */
     errSecIncompatibleKeyBlob                = -67601,    /* The specified database has an incompatible key blob. */
     errSecHostNameMismatch                   = -67602,    /* A host name mismatch has occurred. */
     errSecUnknownCriticalExtensionFlag       = -67603,    /* There is an unknown critical extension flag. */
     errSecNoBasicConstraints                 = -67604,    /* No basic constraints were found. */
     errSecNoBasicConstraintsCA               = -67605,    /* No basic CA constraints were found. */
     errSecInvalidAuthorityKeyID              = -67606,    /* The authority key ID is not valid. */
     errSecInvalidSubjectKeyID                = -67607,    /* The subject key ID is not valid. */
     errSecInvalidKeyUsageForPolicy           = -67608,    /* The key usage is not valid for the specified policy. */
     errSecInvalidExtendedKeyUsage            = -67609,    /* The extended key usage is not valid. */
     errSecInvalidIDLinkage                   = -67610,    /* The ID linkage is not valid. */
     errSecPathLengthConstraintExceeded       = -67611,    /* The path length constraint was exceeded. */
     errSecInvalidRoot                        = -67612,    /* The root or anchor certificate is not valid. */
     errSecCRLExpired                         = -67613,    /* The CRL has expired. */
     errSecCRLNotValidYet                     = -67614,    /* The CRL is not yet valid. */
     errSecCRLNotFound                        = -67615,    /* The CRL was not found. */
     errSecCRLServerDown                      = -67616,    /* The CRL server is down. */
     errSecCRLBadURI                          = -67617,    /* The CRL has a bad Uniform Resource Identifier. */
     errSecUnknownCertExtension               = -67618,    /* An unknown certificate extension was encountered. */
     errSecUnknownCRLExtension                = -67619,    /* An unknown CRL extension was encountered. */
     errSecCRLNotTrusted                      = -67620,    /* The CRL is not trusted. */
     errSecCRLPolicyFailed                    = -67621,    /* The CRL policy failed. */
     errSecIDPFailure                         = -67622,    /* The issuing distribution point was not valid. */
     errSecSMIMEEmailAddressesNotFound        = -67623,    /* An email address mismatch was encountered. */
     errSecSMIMEBadExtendedKeyUsage           = -67624,    /* The appropriate extended key usage for SMIME was not found. */
     errSecSMIMEBadKeyUsage                   = -67625,    /* The key usage is not compatible with SMIME. */
     errSecSMIMEKeyUsageNotCritical           = -67626,    /* The key usage extension is not marked as critical. */
     errSecSMIMENoEmailAddress                = -67627,    /* No email address was found in the certificate. */
     errSecSMIMESubjAltNameNotCritical        = -67628,    /* The subject alternative name extension is not marked as critical. */
     errSecSSLBadExtendedKeyUsage             = -67629,    /* The appropriate extended key usage for SSL was not found. */
     errSecOCSPBadResponse                    = -67630,    /* The OCSP response was incorrect or could not be parsed. */
     errSecOCSPBadRequest                     = -67631,    /* The OCSP request was incorrect or could not be parsed. */
     errSecOCSPUnavailable                    = -67632,    /* OCSP service is unavailable. */
     errSecOCSPStatusUnrecognized             = -67633,    /* The OCSP server did not recognize this certificate. */
     errSecEndOfData                          = -67634,    /* An end-of-data was detected. */
     errSecIncompleteCertRevocationCheck      = -67635,    /* An incomplete certificate revocation check occurred. */
     errSecNetworkFailure                     = -67636,    /* A network failure occurred. */
     errSecOCSPNotTrustedToAnchor             = -67637,    /* The OCSP response was not trusted to a root or anchor certificate. */
     errSecRecordModified                     = -67638,    /* The record was modified. */
     errSecOCSPSignatureError                 = -67639,    /* The OCSP response had an invalid signature. */
     errSecOCSPNoSigner                       = -67640,    /* The OCSP response had no signer. */
     errSecOCSPResponderMalformedReq          = -67641,    /* The OCSP responder was given a malformed request. */
     errSecOCSPResponderInternalError         = -67642,    /* The OCSP responder encountered an internal error. */
     errSecOCSPResponderTryLater              = -67643,    /* The OCSP responder is busy, try again later. */
     errSecOCSPResponderSignatureRequired     = -67644,    /* The OCSP responder requires a signature. */
     errSecOCSPResponderUnauthorized          = -67645,    /* The OCSP responder rejected this request as unauthorized. */
     errSecOCSPResponseNonceMismatch          = -67646,    /* The OCSP response nonce did not match the request. */
     errSecCodeSigningBadCertChainLength      = -67647,    /* Code signing encountered an incorrect certificate chain length. */
     errSecCodeSigningNoBasicConstraints      = -67648,    /* Code signing found no basic constraints. */
     errSecCodeSigningBadPathLengthConstraint = -67649,    /* Code signing encountered an incorrect path length constraint. */
     errSecCodeSigningNoExtendedKeyUsage      = -67650,    /* Code signing found no extended key usage. */
     errSecCodeSigningDevelopment             = -67651,    /* Code signing indicated use of a development-only certificate. */
     errSecResourceSignBadCertChainLength     = -67652,    /* Resource signing has encountered an incorrect certificate chain length. */
     errSecResourceSignBadExtKeyUsage         = -67653,    /* Resource signing has encountered an error in the extended key usage. */
     errSecTrustSettingDeny                   = -67654,    /* The trust setting for this policy was set to Deny. */
     errSecInvalidSubjectName                 = -67655,    /* An invalid certificate subject name was encountered. */
     errSecUnknownQualifiedCertStatement      = -67656,    /* An unknown qualified certificate statement was encountered. */
     errSecMobileMeRequestQueued              = -67657,
     errSecMobileMeRequestRedirected          = -67658,
     errSecMobileMeServerError                = -67659,
     errSecMobileMeServerNotAvailable         = -67660,
     errSecMobileMeServerAlreadyExists        = -67661,
     errSecMobileMeServerServiceErr           = -67662,
     errSecMobileMeRequestAlreadyPending      = -67663,
     errSecMobileMeNoRequestPending           = -67664,
     errSecMobileMeCSRVerifyFailure           = -67665,
     errSecMobileMeFailedConsistencyCheck     = -67666,
     errSecNotInitialized                     = -67667,    /* A function was called without initializing CSSM. */
     errSecInvalidHandleUsage                 = -67668,    /* The CSSM handle does not match with the service type. */
     errSecPVCReferentNotFound                = -67669,    /* A reference to the calling module was not found in the list of authorized callers. */
     errSecFunctionIntegrityFail              = -67670,    /* A function address was not within the verified module. */
     errSecInternalError                      = -67671,    /* An internal error has occurred. */
     errSecMemoryError                        = -67672,    /* A memory error has occurred. */
     errSecInvalidData                        = -67673,    /* Invalid data was encountered. */
     errSecMDSError                           = -67674,    /* A Module Directory Service error has occurred. */
     errSecInvalidPointer                     = -67675,    /* An invalid pointer was encountered. */
     errSecSelfCheckFailed                    = -67676,    /* Self-check has failed. */
     errSecFunctionFailed                     = -67677,    /* A function has failed. */
     errSecModuleManifestVerifyFailed         = -67678,    /* A module manifest verification failure has occurred. */
     errSecInvalidGUID                        = -67679,    /* An invalid GUID was encountered. */
     errSecInvalidHandle                      = -67680,    /* An invalid handle was encountered. */
     errSecInvalidDBList                      = -67681,    /* An invalid DB list was encountered. */
     errSecInvalidPassthroughID               = -67682,    /* An invalid passthrough ID was encountered. */
     errSecInvalidNetworkAddress              = -67683,    /* An invalid network address was encountered. */
     errSecCRLAlreadySigned                   = -67684,    /* The certificate revocation list is already signed. */
     errSecInvalidNumberOfFields              = -67685,    /* An invalid number of fields were encountered. */
     errSecVerificationFailure                = -67686,    /* A verification failure occurred. */
     errSecUnknownTag                         = -67687,    /* An unknown tag was encountered. */
     errSecInvalidSignature                   = -67688,    /* An invalid signature was encountered. */
     errSecInvalidName                        = -67689,    /* An invalid name was encountered. */
     errSecInvalidCertificateRef              = -67690,    /* An invalid certificate reference was encountered. */
     errSecInvalidCertificateGroup            = -67691,    /* An invalid certificate group was encountered. */
     errSecTagNotFound                        = -67692,    /* The specified tag was not found. */
     errSecInvalidQuery                       = -67693,    /* The specified query was not valid. */
     errSecInvalidValue                       = -67694,    /* An invalid value was detected. */
     errSecCallbackFailed                     = -67695,    /* A callback has failed. */
     errSecACLDeleteFailed                    = -67696,    /* An ACL delete operation has failed. */
     errSecACLReplaceFailed                   = -67697,    /* An ACL replace operation has failed. */
     errSecACLAddFailed                       = -67698,    /* An ACL add operation has failed. */
     errSecACLChangeFailed                    = -67699,    /* An ACL change operation has failed. */
     errSecInvalidAccessCredentials           = -67700,    /* Invalid access credentials were encountered. */
     errSecInvalidRecord                      = -67701,    /* An invalid record was encountered. */
     errSecInvalidACL                         = -67702,    /* An invalid ACL was encountered. */
     errSecInvalidSampleValue                 = -67703,    /* An invalid sample value was encountered. */
     errSecIncompatibleVersion                = -67704,    /* An incompatible version was encountered. */
     errSecPrivilegeNotGranted                = -67705,    /* The privilege was not granted. */
     errSecInvalidScope                       = -67706,    /* An invalid scope was encountered. */
     errSecPVCAlreadyConfigured               = -67707,    /* The PVC is already configured. */
     errSecInvalidPVC                         = -67708,    /* An invalid PVC was encountered. */
     errSecEMMLoadFailed                      = -67709,    /* The EMM load has failed. */
     errSecEMMUnloadFailed                    = -67710,    /* The EMM unload has failed. */
     errSecAddinLoadFailed                    = -67711,    /* The add-in load operation has failed. */
     errSecInvalidKeyRef                      = -67712,    /* An invalid key was encountered. */
     errSecInvalidKeyHierarchy                = -67713,    /* An invalid key hierarchy was encountered. */
     errSecAddinUnloadFailed                  = -67714,    /* The add-in unload operation has failed. */
     errSecLibraryReferenceNotFound           = -67715,    /* A library reference was not found. */
     errSecInvalidAddinFunctionTable          = -67716,    /* An invalid add-in function table was encountered. */
     errSecInvalidServiceMask                 = -67717,    /* An invalid service mask was encountered. */
     errSecModuleNotLoaded                    = -67718,    /* A module was not loaded. */
     errSecInvalidSubServiceID                = -67719,    /* An invalid subservice ID was encountered. */
     errSecAttributeNotInContext              = -67720,    /* An attribute was not in the context. */
     errSecModuleManagerInitializeFailed      = -67721,    /* A module failed to initialize. */
     errSecModuleManagerNotFound              = -67722,    /* A module was not found. */
     errSecEventNotificationCallbackNotFound  = -67723,    /* An event notification callback was not found. */
     errSecInputLengthError                   = -67724,    /* An input length error was encountered. */
     errSecOutputLengthError                  = -67725,    /* An output length error was encountered. */
     errSecPrivilegeNotSupported              = -67726,    /* The privilege is not supported. */
     errSecDeviceError                        = -67727,    /* A device error was encountered. */
     errSecAttachHandleBusy                   = -67728,    /* The CSP handle was busy. */
     errSecNotLoggedIn                        = -67729,    /* You are not logged in. */
     errSecAlgorithmMismatch                  = -67730,    /* An algorithm mismatch was encountered. */
     errSecKeyUsageIncorrect                  = -67731,    /* The key usage is incorrect. */
     errSecKeyBlobTypeIncorrect               = -67732,    /* The key blob type is incorrect. */
     errSecKeyHeaderInconsistent              = -67733,    /* The key header is inconsistent. */
     errSecUnsupportedKeyFormat               = -67734,    /* The key header format is not supported. */
     errSecUnsupportedKeySize                 = -67735,    /* The key size is not supported. */
     errSecInvalidKeyUsageMask                = -67736,    /* The key usage mask is not valid. */
     errSecUnsupportedKeyUsageMask            = -67737,    /* The key usage mask is not supported. */
     errSecInvalidKeyAttributeMask            = -67738,    /* The key attribute mask is not valid. */
     errSecUnsupportedKeyAttributeMask        = -67739,    /* The key attribute mask is not supported. */
     errSecInvalidKeyLabel                    = -67740,    /* The key label is not valid. */
     errSecUnsupportedKeyLabel                = -67741,    /* The key label is not supported. */
     errSecInvalidKeyFormat                   = -67742,    /* The key format is not valid. */
     errSecUnsupportedVectorOfBuffers         = -67743,    /* The vector of buffers is not supported. */
     errSecInvalidInputVector                 = -67744,    /* The input vector is not valid. */
     errSecInvalidOutputVector                = -67745,    /* The output vector is not valid. */
     errSecInvalidContext                     = -67746,    /* An invalid context was encountered. */
     errSecInvalidAlgorithm                   = -67747,    /* An invalid algorithm was encountered. */
     errSecInvalidAttributeKey                = -67748,    /* A key attribute was not valid. */
     errSecMissingAttributeKey                = -67749,    /* A key attribute was missing. */
     errSecInvalidAttributeInitVector         = -67750,    /* An init vector attribute was not valid. */
     errSecMissingAttributeInitVector         = -67751,    /* An init vector attribute was missing. */
     errSecInvalidAttributeSalt               = -67752,    /* A salt attribute was not valid. */
     errSecMissingAttributeSalt               = -67753,    /* A salt attribute was missing. */
     errSecInvalidAttributePadding            = -67754,    /* A padding attribute was not valid. */
     errSecMissingAttributePadding            = -67755,    /* A padding attribute was missing. */
     errSecInvalidAttributeRandom             = -67756,    /* A random number attribute was not valid. */
     errSecMissingAttributeRandom             = -67757,    /* A random number attribute was missing. */
     errSecInvalidAttributeSeed               = -67758,    /* A seed attribute was not valid. */
     errSecMissingAttributeSeed               = -67759,    /* A seed attribute was missing. */
     errSecInvalidAttributePassphrase         = -67760,    /* A passphrase attribute was not valid. */
     errSecMissingAttributePassphrase         = -67761,    /* A passphrase attribute was missing. */
     errSecInvalidAttributeKeyLength          = -67762,    /* A key length attribute was not valid. */
     errSecMissingAttributeKeyLength          = -67763,    /* A key length attribute was missing. */
     errSecInvalidAttributeBlockSize          = -67764,    /* A block size attribute was not valid. */
     errSecMissingAttributeBlockSize          = -67765,    /* A block size attribute was missing. */
     errSecInvalidAttributeOutputSize         = -67766,    /* An output size attribute was not valid. */
     errSecMissingAttributeOutputSize         = -67767,    /* An output size attribute was missing. */
     errSecInvalidAttributeRounds             = -67768,    /* The number of rounds attribute was not valid. */
     errSecMissingAttributeRounds             = -67769,    /* The number of rounds attribute was missing. */
     errSecInvalidAlgorithmParms              = -67770,    /* An algorithm parameters attribute was not valid. */
     errSecMissingAlgorithmParms              = -67771,    /* An algorithm parameters attribute was missing. */
     errSecInvalidAttributeLabel              = -67772,    /* A label attribute was not valid. */
     errSecMissingAttributeLabel              = -67773,    /* A label attribute was missing. */
     errSecInvalidAttributeKeyType            = -67774,    /* A key type attribute was not valid. */
     errSecMissingAttributeKeyType            = -67775,    /* A key type attribute was missing. */
     errSecInvalidAttributeMode               = -67776,    /* A mode attribute was not valid. */
     errSecMissingAttributeMode               = -67777,    /* A mode attribute was missing. */
     errSecInvalidAttributeEffectiveBits      = -67778,    /* An effective bits attribute was not valid. */
     errSecMissingAttributeEffectiveBits      = -67779,    /* An effective bits attribute was missing. */
     errSecInvalidAttributeStartDate          = -67780,    /* A start date attribute was not valid. */
     errSecMissingAttributeStartDate          = -67781,    /* A start date attribute was missing. */
     errSecInvalidAttributeEndDate            = -67782,    /* An end date attribute was not valid. */
     errSecMissingAttributeEndDate            = -67783,    /* An end date attribute was missing. */
     errSecInvalidAttributeVersion            = -67784,    /* A version attribute was not valid. */
     errSecMissingAttributeVersion            = -67785,    /* A version attribute was missing. */
     errSecInvalidAttributePrime              = -67786,    /* A prime attribute was not valid. */
     errSecMissingAttributePrime              = -67787,    /* A prime attribute was missing. */
     errSecInvalidAttributeBase               = -67788,    /* A base attribute was not valid. */
     errSecMissingAttributeBase               = -67789,    /* A base attribute was missing. */
     errSecInvalidAttributeSubprime           = -67790,    /* A subprime attribute was not valid. */
     errSecMissingAttributeSubprime           = -67791,    /* A subprime attribute was missing. */
     errSecInvalidAttributeIterationCount     = -67792,    /* An iteration count attribute was not valid. */
     errSecMissingAttributeIterationCount     = -67793,    /* An iteration count attribute was missing. */
     errSecInvalidAttributeDLDBHandle         = -67794,    /* A database handle attribute was not valid. */
     errSecMissingAttributeDLDBHandle         = -67795,    /* A database handle attribute was missing. */
     errSecInvalidAttributeAccessCredentials  = -67796,    /* An access credentials attribute was not valid. */
     errSecMissingAttributeAccessCredentials  = -67797,    /* An access credentials attribute was missing. */
     errSecInvalidAttributePublicKeyFormat    = -67798,    /* A public key format attribute was not valid. */
     errSecMissingAttributePublicKeyFormat    = -67799,    /* A public key format attribute was missing. */
     errSecInvalidAttributePrivateKeyFormat   = -67800,    /* A private key format attribute was not valid. */
     errSecMissingAttributePrivateKeyFormat   = -67801,    /* A private key format attribute was missing. */
     errSecInvalidAttributeSymmetricKeyFormat = -67802,    /* A symmetric key format attribute was not valid. */
     errSecMissingAttributeSymmetricKeyFormat = -67803,    /* A symmetric key format attribute was missing. */
     errSecInvalidAttributeWrappedKeyFormat   = -67804,    /* A wrapped key format attribute was not valid. */
     errSecMissingAttributeWrappedKeyFormat   = -67805,    /* A wrapped key format attribute was missing. */
     errSecStagedOperationInProgress          = -67806,    /* A staged operation is in progress. */
     errSecStagedOperationNotStarted          = -67807,    /* A staged operation was not started. */
     errSecVerifyFailed                       = -67808,    /* A cryptographic verification failure has occurred. */
     errSecQuerySizeUnknown                   = -67809,    /* The query size is unknown. */
     errSecBlockSizeMismatch                  = -67810,    /* A block size mismatch occurred. */
     errSecPublicKeyInconsistent              = -67811,    /* The public key was inconsistent. */
     errSecDeviceVerifyFailed                 = -67812,    /* A device verification failure has occurred. */
     errSecInvalidLoginName                   = -67813,    /* An invalid login name was detected. */
     errSecAlreadyLoggedIn                    = -67814,    /* The user is already logged in. */
     errSecInvalidDigestAlgorithm             = -67815,    /* An invalid digest algorithm was detected. */
     errSecInvalidCRLGroup                    = -67816,    /* An invalid CRL group was detected. */
     errSecCertificateCannotOperate           = -67817,    /* The certificate cannot operate. */
     errSecCertificateExpired                 = -67818,    /* An expired certificate was detected. */
     errSecCertificateNotValidYet             = -67819,    /* The certificate is not yet valid. */
     errSecCertificateRevoked                 = -67820,    /* The certificate was revoked. */
     errSecCertificateSuspended               = -67821,    /* The certificate was suspended. */
     errSecInsufficientCredentials            = -67822,    /* Insufficient credentials were detected. */
     errSecInvalidAction                      = -67823,    /* The action was not valid. */
     errSecInvalidAuthority                   = -67824,    /* The authority was not valid. */
     errSecVerifyActionFailed                 = -67825,    /* A verify action has failed. */
     errSecInvalidCertAuthority               = -67826,    /* The certificate authority was not valid. */
     errSecInvaldCRLAuthority                 = -67827,    /* The CRL authority was not valid. */
     errSecInvalidCRLEncoding                 = -67828,    /* The CRL encoding was not valid. */
     errSecInvalidCRLType                     = -67829,    /* The CRL type was not valid. */
     errSecInvalidCRL                         = -67830,    /* The CRL was not valid. */
     errSecInvalidFormType                    = -67831,    /* The form type was not valid. */
     errSecInvalidID                          = -67832,    /* The ID was not valid. */
     errSecInvalidIdentifier                  = -67833,    /* The identifier was not valid. */
     errSecInvalidIndex                       = -67834,    /* The index was not valid. */
     errSecInvalidPolicyIdentifiers           = -67835,    /* The policy identifiers are not valid. */
     errSecInvalidTimeString                  = -67836,    /* The time specified was not valid. */
     errSecInvalidReason                      = -67837,    /* The trust policy reason was not valid. */
     errSecInvalidRequestInputs               = -67838,    /* The request inputs are not valid. */
     errSecInvalidResponseVector              = -67839,    /* The response vector was not valid. */
     errSecInvalidStopOnPolicy                = -67840,    /* The stop-on policy was not valid. */
     errSecInvalidTuple                       = -67841,    /* The tuple was not valid. */
     errSecMultipleValuesUnsupported          = -67842,    /* Multiple values are not supported. */
     errSecNotTrusted                         = -67843,    /* The certificate was not trusted. */
     errSecNoDefaultAuthority                 = -67844,    /* No default authority was detected. */
     errSecRejectedForm                       = -67845,    /* The trust policy had a rejected form. */
     errSecRequestLost                        = -67846,    /* The request was lost. */
     errSecRequestRejected                    = -67847,    /* The request was rejected. */
     errSecUnsupportedAddressType             = -67848,    /* The address type is not supported. */
     errSecUnsupportedService                 = -67849,    /* The service is not supported. */
     errSecInvalidTupleGroup                  = -67850,    /* The tuple group was not valid. */
     errSecInvalidBaseACLs                    = -67851,    /* The base ACLs are not valid. */
     errSecInvalidTupleCredendtials           = -67852,    /* The tuple credentials are not valid. */
     errSecInvalidEncoding                    = -67853,    /* The encoding was not valid. */
     errSecInvalidValidityPeriod              = -67854,    /* The validity period was not valid. */
     errSecInvalidRequestor                   = -67855,    /* The requestor was not valid. */
     errSecRequestDescriptor                  = -67856,    /* The request descriptor was not valid. */
     errSecInvalidBundleInfo                  = -67857,    /* The bundle information was not valid. */
     errSecInvalidCRLIndex                    = -67858,    /* The CRL index was not valid. */
     errSecNoFieldValues                      = -67859,    /* No field values were detected. */
     errSecUnsupportedFieldFormat             = -67860,    /* The field format is not supported. */
     errSecUnsupportedIndexInfo               = -67861,    /* The index information is not supported. */
     errSecUnsupportedLocality                = -67862,    /* The locality is not supported. */
     errSecUnsupportedNumAttributes           = -67863,    /* The number of attributes is not supported. */
     errSecUnsupportedNumIndexes              = -67864,    /* The number of indexes is not supported. */
     errSecUnsupportedNumRecordTypes          = -67865,    /* The number of record types is not supported. */
     errSecFieldSpecifiedMultiple             = -67866,    /* Too many fields were specified. */
     errSecIncompatibleFieldFormat            = -67867,    /* The field format was incompatible. */
     errSecInvalidParsingModule               = -67868,    /* The parsing module was not valid. */
     errSecDatabaseLocked                     = -67869,    /* The database is locked. */
     errSecDatastoreIsOpen                    = -67870,    /* The data store is open. */
     errSecMissingValue                       = -67871,    /* A missing value was detected. */
     errSecUnsupportedQueryLimits             = -67872,    /* The query limits are not supported. */
     errSecUnsupportedNumSelectionPreds       = -67873,    /* The number of selection predicates is not supported. */
     errSecUnsupportedOperator                = -67874,    /* The operator is not supported. */
     errSecInvalidDBLocation                  = -67875,    /* The database location is not valid. */
     errSecInvalidAccessRequest               = -67876,    /* The access request is not valid. */
     errSecInvalidIndexInfo                   = -67877,    /* The index information is not valid. */
     errSecInvalidNewOwner                    = -67878,    /* The new owner is not valid. */
     errSecInvalidModifyMode                  = -67879,    /* The modify mode is not valid. */
     errSecMissingRequiredExtension           = -67880,    /* A required certificate extension is missing. */
     errSecExtendedKeyUsageNotCritical        = -67881,    /* The extended key usage extension was not marked critical. */
     errSecTimestampMissing                   = -67882,    /* A timestamp was expected but was not found. */
     errSecTimestampInvalid                   = -67883,    /* The timestamp was not valid. */
     errSecTimestampNotTrusted                = -67884,    /* The timestamp was not trusted. */
     errSecTimestampServiceNotAvailable       = -67885,    /* The timestamp service is not available. */
     errSecTimestampBadAlg                    = -67886,    /* An unrecognized or unsupported Algorithm Identifier in timestamp. */
     errSecTimestampBadRequest                = -67887,    /* The timestamp transaction is not permitted or supported. */
     errSecTimestampBadDataFormat             = -67888,    /* The timestamp data submitted has the wrong format. */
     errSecTimestampTimeNotAvailable          = -67889,    /* The time source for the Timestamp Authority is not available. */
     errSecTimestampUnacceptedPolicy          = -67890,    /* The requested policy is not supported by the Timestamp Authority. */
     errSecTimestampUnacceptedExtension       = -67891,    /* The requested extension is not supported by the Timestamp Authority. */
     errSecTimestampAddInfoNotAvailable       = -67892,    /* The additional information requested is not available. */
     errSecTimestampSystemFailure             = -67893,    /* The timestamp request cannot be handled due to system failure. */
     errSecSigningTimeMissing                 = -67894,    /* A signing time was expected but was not found. */
     errSecTimestampRejection                 = -67895,    /* A timestamp transaction was rejected. */
     errSecTimestampWaiting                   = -67896,    /* A timestamp transaction is waiting. */
     errSecTimestampRevocationWarning         = -67897,    /* A timestamp authority revocation warning was issued. */
     errSecTimestampRevocationNotification    = -67898,    /* A timestamp authority revocation notification was issued. */
 };

 
 */
