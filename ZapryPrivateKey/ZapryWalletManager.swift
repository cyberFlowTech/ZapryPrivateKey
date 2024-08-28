//
//  ZapryWalletManager.swift
//  MIMO
//
//  Created by gaofeng on 2023/10/16.
//

import Foundation
import KeychainAccess

public struct ZapryWalletModel: Codable {
    public var mnemonic: String = ""
    public var accountAddress: String = ""
    public var accountPrivateKey: String = ""
    public var coinType = 0
    public var multiWalletInfo: String = ""
}

@objcMembers public class ZapryWalletManager: NSObject {
    
    //shy:由于2.8之前的privateKey是存储在UserDefault上的，所以需要兼容老版本，只获取不存
    public static var kMultiUdKey: String {
        "\(ZapryPrivateKeyHelper.shared.getUserIdFromOptions())-multi-walletInfo"
    }
    //shy：2.8之后的非敏感数据address存储在userDefault上的
    public static var kAddressKey: String {
        "\(ZapryPrivateKeyHelper.shared.getUserIdFromOptions())-multi-walletInfo-address"
    }
    public static var kCurrentBackupID: String {
        "\(ZapryPrivateKeyHelper.shared.getUserIdFromOptions())-multi-walletInfo-currnet-backupID"
    }
    public static func getCurrentBackupID() -> String? {
        return UserDefaults.standard.value(forKey: ZapryWalletManager.kCurrentBackupID) as? String
    }
    public static func setCurrentBackupID(backupID: String) {
        ZapryUtil.saveObject(object: backupID, key: ZapryWalletManager.kCurrentBackupID)
    }
    
    public static let shared = ZapryWalletManager()
    
    static func setMultiWalletInfo(mnemonic:String,wallet:[String: Any],password:String,backupID:String?,completion:@escaping (Bool,String)->Void) {
        guard !mnemonic.isEmpty,!wallet.isEmpty else {
            completion(false,"")
            return
        }
        if (ZapryWalletManager.saveWallet(mnemonic: mnemonic, multiWalletInfo: wallet,password:password) ) {
            if let extData = backupID {
                ZapryWalletManager.setCurrentBackupID(backupID: extData)
            }
            completion(true,"")
        } else {
            completion(false,"")
        }
    }
    
    static func getWalletModel(password:String) -> ZapryWalletModel? { // 注意如果是支付密码方式，需要有密码
        var model: ZapryWalletModel? = nil
        let type = ZapryPrivateKeyHelper.shared.getPaymentVerificationMethod()
        switch type {
        case .faceID, .touchID:
            if let s = ZaprySecurityStore.getWalletThatAuthByBiometric() {
                model = ZapryWalletManager.stringToModel(s: s)
            }
        case .password:
            if let s = ZaprySecurityStore.getWalletThatAuthByPayPassword(payPassword:password) {
                model = ZapryWalletManager.stringToModel(s: s)
            }
        case .none,.denyBiometry,.lock:
            if let s = UserDefaults.standard.value(forKey: ZapryWalletManager.kMultiUdKey) as? String {
                model = ZapryWalletManager.stringToModel(s: s)
            }
        }
        return model
    }
    
    static func currentWalletHasBackup() -> Bool {
        guard let c = ZapryWalletManager.getCurrentBackupID() else { return false }
        let ks = ZaprySecurityStore.getUndecryptWalletsThatAuthByBackupPassword().keys
        return ks.contains(c)
    }
    
    static func saveWallet(mnemonic: String, multiWalletInfo: [String: Any],password:String) -> Bool {
        guard let info = ZapryJSONUtil.dicToJsonString(dic: multiWalletInfo) else { return false }
        var model = ZapryWalletModel()
        model.mnemonic = mnemonic
        model.multiWalletInfo = info
        let type = ZapryPrivateKeyHelper.shared.getPaymentVerificationMethod()
        return ZapryWalletManager.saveModelToSecurityStore(model: model, targetType: type,password: password)
    }
    
    static func transferToSecurityStoreIfNeeded(targetType: ZapryDeviceBiometricType, walletModel:ZapryWalletModel?,password:String) -> Bool { // 如果安全存储中没有，会从旧存储中读取并迁移到安全存储中
        var model:ZapryWalletModel?
        if let walletModel = walletModel {
            model = walletModel
        }else {
            model = ZapryWalletManager.getWalletModel(password:password)
        }
        if ( model == nil ) {
            if let s = UserDefaults.standard.value(forKey: ZapryWalletManager.kMultiUdKey) as? String {
                model = ZapryWalletManager.stringToModel(s: s)
            }
        }
        // 这2个是临时变量，对应某个链，所以不需要保存
        model?.accountAddress = ""
        model?.accountPrivateKey = ""
        if let m = model {
            if ( ZapryWalletManager.saveModelToSecurityStore(model: m, targetType: targetType,password: password) ) {
                return true
            }
        } else {
            if ( ZapryWalletManager.getWalletAddress().count <= 0 ) { // new wallet
                return true
            }
        }
        return false
    }
    
    static func saveModelToSecurityStore(model: ZapryWalletModel, targetType: ZapryDeviceBiometricType,password:String) -> Bool {
        ZapryUtil.saveObject(object: "", key: ZapryWalletManager.kAddressKey)
        var success = false
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(model) else { return false }
        guard let modelStr = String(data: data, encoding: .utf8) else { return false }
        switch targetType {
        case .faceID, .touchID:
            success = ZaprySecurityStore.setWalletThatAuthByBiometric(walletInfo: modelStr)
            if ( success ) {
                _ = ZaprySecurityStore.deleteWalletThatAuthByPayPassword()
            }
        case .password:
            //shytodo 保存支付密码需求去掉
            success = ZaprySecurityStore.setWalletThatAuthByPayPassword(walletInfo: modelStr, payPassword:password)
            if ( success ) {
                _ = ZaprySecurityStore.deleteWalletThatAuthByBiometric()
            }
        case .none,.denyBiometry,.lock:
            let window = ZapryUtil.keyWindow()
            ZapryUtil.makeToast(ZapryNSI18n.shared.biometric_setting_save_wallet,isError: true, forView:window)
        }
        if ( success ) {
            if let adds = ZapryWalletManager.getMultiAddressFromModel(model: model) { // 非敏感信息单独存储，不需要密码验证就可以使用
                if let s = ZapryJSONUtil.dicToJsonString(dic: adds) {
                    ZapryUtil.saveObject(object: s, key: ZapryWalletManager.kAddressKey)
                    ZapryWalletManager.deleteOldWallet()
                }
            }
        }
        return success
    }
    
    static func backupCurrentWallet(backupPassword: String,password:String) -> String? {
        let model = ZapryWalletManager.getWalletModel(password: password)
        if let m = model?.mnemonic {
            if let backupID = ZaprySecurityStore.saveWalletThatAuthByBackupPassword(walletInfo: m, backupPassword: backupPassword) {
                ZapryWalletManager.setCurrentBackupID(backupID: backupID)
                return backupID
            }
        }
        return nil
    }

    // RN还在用，先保留一段时间吧，后面要删掉了，尽量不要使用
    static func getWalletInfo(chainCode: String,password:String) -> [String: Any]? {
        var result: [String: Any] = [:]
        if let model = ZapryWalletManager.getWalletModel(password: password) {
            let multi = model.multiWalletInfo
            guard let info = ZapryJSONUtil.stringToDic(multi) else {
                return nil
            }
            for (key, value) in info {
                if chainCode == key {
                    result["mnemonic"] = model.mnemonic
                    result["wallet"] = value
                }
            }
            return result
        }
        return nil
    }
    
    static func getMultiAddress() -> [String: String]? {
        let type = ZapryPrivateKeyHelper.shared.getPaymentVerificationMethod()
        if ( type == .password ) { // 一个补丁：修复两个存储不一致的情况
            if ( ZaprySecurityStore.hasWalletThatAuthByPayPassword() == false ) {
                return nil
            }
        }
        // 取非敏感数据
        switch type {
        case .faceID, .touchID, .password:
            if let s = UserDefaults.standard.value(forKey: ZapryWalletManager.kAddressKey) as? String {
                if let dic = ZapryJSONUtil.stringToDic(s) {
                    var result: [String: String] = [:]
                    for (k, v) in dic {
                        if let vv = v as? String {
                            result[k] = vv
                        }
                    }
                    return result
                }
            }
        case .none,.denyBiometry,.lock:
            if let s = UserDefaults.standard.value(forKey: ZapryWalletManager.kMultiUdKey) as? String {
                if let model = ZapryWalletManager.stringToModel(s: s) {
                    return ZapryWalletManager.getMultiAddressFromModel(model: model)
                }
            }
        }
        return nil
    }
    
    public static func getMultiAddressFromModel(model: ZapryWalletModel) -> [String: String]? {
        var result: [String: String] = [:]
        let multi = model.multiWalletInfo
        guard let info = ZapryJSONUtil.stringToDic(multi) else { return nil }
        for (key, value) in info {
            if let wallet = value as? [String: String] {
                result[key] = wallet["address"]
            }
        }
        return result
    }
    
    public static func stringToModel(s: String, chainCode: String = "2000000") -> ZapryWalletModel? {
        let decoder = JSONDecoder()
        guard let data = s.data(using: .utf8) else { return nil }
        guard var model = try? decoder.decode(ZapryWalletModel.self, from: data) else { return nil }
        guard let info = ZapryJSONUtil.stringToDic(model.multiWalletInfo) else { return nil }
        for (key, value) in info {
            if chainCode == key {
                if let wallet = value as? [String: String] {
                    model.accountAddress = wallet["address"] ?? ""
                    model.accountPrivateKey = wallet["privateKey"] ?? ""
                }
            }
        }
        return model
    }
    
    public static func modelToStr(model:ZapryWalletModel) -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(model) else { return nil }
        guard let modelStr = String(data: data, encoding: .utf8) else { return nil }
        return modelStr
    }
    
    public static func remove(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    static func deleteWallet() {
        self.deleteOldWallet()
        self.deleteNewWallet()
    }
    
    static func deleteNewWallet() {
        _ = ZaprySecurityStore.deleteWalletThatAuthByBiometric()
        _ = ZaprySecurityStore.deleteWalletThatAuthByPayPassword()
        ZapryUtil.saveObject(object: "", key: ZapryWalletManager.kAddressKey)
        ZapryWalletManager.setCurrentBackupID(backupID: "")
    }
    
    static func deleteOldWallet() {
        let singleChainWalletInfo = "\(ZapryPrivateKeyHelper.shared.getUserIdFromOptions())-walletInfo"
        ZapryWalletManager.remove(key: singleChainWalletInfo)
        ZapryWalletManager.remove(key: ZapryWalletManager.kMultiUdKey)
    }
    
    static func getWalletAddress(chainCode:String="2000000") -> String {
        guard let dic = ZapryWalletManager.getMultiAddress() else { return "" }
        guard let address = dic[chainCode] else { return "" }
        return address
    }
    
    public static func getOldWalletAddress() -> String {
        if let s = UserDefaults.standard.value(forKey: ZapryWalletManager.kMultiUdKey) as? String {
            if let model = ZapryWalletManager.stringToModel(s: s) {
                guard let dic = ZapryWalletManager.getMultiAddressFromModel(model: model) else { return "" }
                guard let address = dic["2000000"] else { return "" }
                return address
            }
        }
        return ""
    }
    
    public static func getChainCode(chainCode:String) -> String {
        let etmpChainCodeSeries:[String] = ["1000000","2000000","2010000","1010000","1020000","1030000","1040000","5000001","5000002","5000004","5000005"]
        if etmpChainCodeSeries.contains(chainCode) {
            return "2000000"
        }
        return chainCode
    }
}
