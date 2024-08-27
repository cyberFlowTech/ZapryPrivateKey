//
//  WalletManager.swift
//  MIMO
//
//  Created by gaofeng on 2023/10/16.
//

import Foundation
import KeychainAccess

public struct WalletModel: Codable {
    public var mnemonic: String = ""
    public var accountAddress: String = ""
    public var accountPrivateKey: String = ""
    public var coinType = 0
    public var multiWalletInfo: String = ""
}

@objcMembers public class WalletManager: NSObject {
    
    public static var kMultiUdKey: String {
        "\(UserConfig.shared.userId)-multi-walletInfo"
    }
    public static var kAddressKey: String {
        "\(UserConfig.shared.userId)-multi-walletInfo-address"
    }
    public static var kCurrentBackupID: String {
        "\(UserConfig.shared.userId)-multi-walletInfo-currnet-backupID"
    }
    public static func getCurrentBackupID() -> String? {
        return UserDefaults.standard.value(forKey: WalletManager.kCurrentBackupID) as? String
    }
    public static func setCurrentBackupID(backupID: String) {
        UserDefaultsUtil.saveObject(object: backupID, key: WalletManager.kCurrentBackupID)
    }
    
    public static let shared = WalletManager()
    
    public static func getWalletModel(password:String) -> WalletModel? { // 注意如果是支付密码方式，需要有密码
        var model: WalletModel? = nil
        let type = UserConfig.read()
        switch type {
        case .faceID, .touchID:
            if let s = MMSecurityStore.getWalletThatAuthByBiometric() {
                model = WalletManager.stringToModel(s: s)
            }
        case .password:
            if let s = MMSecurityStore.getWalletThatAuthByPayPassword(payPassword:password) {
                model = WalletManager.stringToModel(s: s)
            }
        case .none,.denyBiometry,.lock:
            if let s = UserDefaults.standard.value(forKey: WalletManager.kMultiUdKey) as? String {
                model = WalletManager.stringToModel(s: s)
            }
        }
        return model
    }
    
    public static func currentWalletHasBackup() -> Bool {
        guard let c = WalletManager.getCurrentBackupID() else { return false }
        let ks = MMSecurityStore.getUndecryptWalletsThatAuthByBackupPassword().keys
        return ks.contains(c)
    }
    
    public static func saveWallet(mnemonic: String, multiWalletInfo: [String: Any],password:String) -> Bool {
        guard let info = JSONUtil.dicToJsonString(dic: multiWalletInfo) else { return false }
        var model = WalletModel()
        model.mnemonic = mnemonic
        model.multiWalletInfo = info
        let type = UserConfig.read()
        return WalletManager.saveModelToSecurityStore(model: model, targetType: type,password: password)
    }
    
    public static func transferToSecurityStoreIfNeeded(targetType: VerificationType, walletModel:WalletModel?,password:String) -> Bool { // 如果安全存储中没有，会从旧存储中读取并迁移到安全存储中
        var model:WalletModel?
        if let walletModel = walletModel {
            model = walletModel
        }else {
            model = WalletManager.getWalletModel(password:password)
        }
        if ( model == nil ) {
            if let s = UserDefaults.standard.value(forKey: WalletManager.kMultiUdKey) as? String {
                model = WalletManager.stringToModel(s: s)
            }
        }
        // 这2个是临时变量，对应某个链，所以不需要保存
        model?.accountAddress = ""
        model?.accountPrivateKey = ""
        if let m = model {
            if ( WalletManager.saveModelToSecurityStore(model: m, targetType: targetType,password: password) ) {
                return true
            }
        } else {
            if ( WalletManager.getWalletAddress().count <= 0 ) { // new wallet
                return true
            }
        }
        return false
    }
    
    public static func saveModelToSecurityStore(model: WalletModel, targetType: VerificationType,password:String) -> Bool {
        UserDefaultsUtil.saveObject(object: "", key: WalletManager.kAddressKey)
        var success = false
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(model) else { return false }
        guard let modelStr = String(data: data, encoding: .utf8) else { return false }
        switch targetType {
        case .faceID, .touchID:
            success = MMSecurityStore.setWalletThatAuthByBiometric(walletInfo: modelStr)
            if ( success ) {
                _ = MMSecurityStore.deleteWalletThatAuthByPayPassword()
            }
        case .password:
            //shytodo 保存支付密码需求去掉
            success = MMSecurityStore.setWalletThatAuthByPayPassword(walletInfo: modelStr, payPassword:password)
            if ( success ) {
                _ = MMSecurityStore.deleteWalletThatAuthByBiometric()
            }
        case .none,.denyBiometry,.lock:
            let window = ZapryUtil.keyWindow()
            MMToast.makeToast("未设置验证方式不能保存钱包",isError: true, forView:window)
        }
        if ( success ) {
            if let adds = WalletManager.getMultiAddressFromModel(model: model) { // 非敏感信息单独存储，不需要密码验证就可以使用
                if let s = JSONUtil.dicToJsonString(dic: adds) {
                    UserDefaultsUtil.saveObject(object: s, key: WalletManager.kAddressKey)
                    WalletManager.deleteOldWallet()
                }
            }
        }
        return success
    }
    
    public static func backupCurrentWallet(backupPassword: String,password:String) -> String? {
        let model = WalletManager.getWalletModel(password: password)
        if let m = model?.mnemonic {
            if let backupID = MMSecurityStore.saveWalletThatAuthByBackupPassword(walletInfo: m, backupPassword: backupPassword) {
                WalletManager.setCurrentBackupID(backupID: backupID)
                return backupID
            }
        }
        return nil
    }

    // RN还在用，先保留一段时间吧，后面要删掉了，尽量不要使用
    public static func getWalletInfo(chainCode: String,password:String) -> [String: Any]? {
        var result: [String: Any] = [:]
        if let model = WalletManager.getWalletModel(password: password) {
            let multi = model.multiWalletInfo
            guard let info = JSONUtil.stringToDic(multi) else {
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
    
    public static func getMultiAddress() -> [String: String]? {
        let type = UserConfig.read()
        if ( type == .password ) { // 一个补丁：修复两个存储不一致的情况
            if ( MMSecurityStore.hasWalletThatAuthByPayPassword() == false ) {
                return nil
            }
        }
        // 取非敏感数据
        switch type {
        case .faceID, .touchID, .password:
            if let s = UserDefaults.standard.value(forKey: WalletManager.kAddressKey) as? String {
                if let dic = JSONUtil.stringToDic(s) {
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
            if let s = UserDefaults.standard.value(forKey: WalletManager.kMultiUdKey) as? String {
                if let model = WalletManager.stringToModel(s: s) {
                    return WalletManager.getMultiAddressFromModel(model: model)
                }
            }
        }
        return nil
    }
    
    public static func getMultiAddressFromModel(model: WalletModel) -> [String: String]? {
        var result: [String: String] = [:]
        let multi = model.multiWalletInfo
        guard let info = JSONUtil.stringToDic(multi) else { return nil }
        for (key, value) in info {
            if let wallet = value as? [String: String] {
                result[key] = wallet["address"]
            }
        }
        return result
    }
    
    public static func stringToModel(s: String, chainCode: String = "2000000") -> WalletModel? {
        let decoder = JSONDecoder()
        guard let data = s.data(using: .utf8) else { return nil }
        guard var model = try? decoder.decode(WalletModel.self, from: data) else { return nil }
        guard let info = JSONUtil.stringToDic(model.multiWalletInfo) else { return nil }
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
    
    public static func modelToStr(model:WalletModel) -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(model) else { return nil }
        guard let modelStr = String(data: data, encoding: .utf8) else { return nil }
        return modelStr
    }
    
    public static func remove(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    public static func deleteWallet() {
        self.deleteOldWallet()
        self.deleteNewWallet()
    }
    
    public static func deleteNewWallet() {
        _ = MMSecurityStore.deleteWalletThatAuthByBiometric()
        _ = MMSecurityStore.deleteWalletThatAuthByPayPassword()
        UserDefaultsUtil.saveObject(object: "", key: WalletManager.kAddressKey)
        WalletManager.setCurrentBackupID(backupID: "")
    }
    
    public static func deleteOldWallet() {
        let singleChainWalletInfo = "\(UserConfig.shared.userId)-walletInfo"
        WalletManager.remove(key: singleChainWalletInfo)
        WalletManager.remove(key: WalletManager.kMultiUdKey)
    }
    
    public static func getWalletAddress(chainCode:String="2000000") -> String {
        guard let dic = WalletManager.getMultiAddress() else { return "" }
        guard let address = dic[chainCode] else { return "" }
        return address
    }
    
    public static func getOldWalletAddress() -> String {
        if let s = UserDefaults.standard.value(forKey: WalletManager.kMultiUdKey) as? String {
            if let model = WalletManager.stringToModel(s: s) {
                guard let dic = WalletManager.getMultiAddressFromModel(model: model) else { return "" }
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
