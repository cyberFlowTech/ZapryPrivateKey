//
//  ZapryPrivateKeyHelper.swift
//  MIMO
//
//  Created by admin  on 2024/3/7.
//

import Foundation
import UIKit
import HandyJSON

public enum ZapryResultAction:Int {
    case none = 0 // 跳过
    case success = 1 //成功
    case fail = 2 //失败
    case set = 3 //设置
    case close = 4 //关闭
}

@objcMembers
class ZapryPayModel:NSObject,HandyJSON {
    public var amount:String = "0.00"
    public var chainCode:String = ""
    public var nick:String = ""
    public var to:String = ""
    public var payPassword:String = ""
    public var token:[String:Any]?
    public var signType:Int = 0
    public var signData:[String:Any] = [String : Any]()
    public var nftTokenId:String = ""
    public var nftName:String = ""
    
    required public override init() {}
}

@objcMembers
public class ZapryUserInfoModel:NSObject {
    public var userId:String
    public var lan:ZaprySDKLanguange = .en
    public init(userId:String,language:ZaprySDKLanguange = .en) {
        self.userId = userId
        self.lan = language
    }
}


@objcMembers
public class ZapryPrivateKeyHelper: NSObject {
    public static let shared = ZapryPrivateKeyHelper()
    public static let ERROR_CODE_BIOMETRIC_FAILED:Int = -10001
    public static let ERROR_CODE_PASSWORD_FAILED:Int = -10002
    public static let ZAPRY_REPROT_NOTIFICATION = Notification.Name("Zapry_Report_Notification")
    private var sceneListWithoutUI:[ZaprySceneType] = [.unBind,.checkMnemonicWord,.CreateWallet,.VerificationBiometic,.PayPasswordAuth,.AddNewChain,.CloudBackup,.Sign]
    public var CompletionHandle: ((_ type:Int) -> Void)?
    
    var zapryOptions:ZapryUserInfoModel?
    public var payTypeWithCache:ZapryDeviceBiometricType = .none 
    
    public func initOptions(userId:String,language:ZaprySDKLanguange = .en) {
        if userId.isEmpty {
            DispatchQueue.main.async {
                ZapryUtil.makeToast("userId is empty", isError:true, forView: ZapryUtil.keyWindow())
            }
            return
        }
        self.zapryOptions = ZapryUserInfoModel(userId: userId,language:language)
        ZapryUtil.shared.setPreferredLanguage(lan:language)
        self.payTypeWithCache = self.getPaymentVerificationMethod(isCache:false)
    }
    
    public func changeLanOptions(lanaguage:ZaprySDKLanguange) {
        guard self.checkOptions() else {
            self.checkPrivateKeyInit(method: "changeLanOptions")
            return
        }
        self.zapryOptions?.lan = lanaguage
        ZapryUtil.shared.setPreferredLanguage(lan: lanaguage)
    }
    
    public func checkOptions() -> Bool {
        var isInit:Bool = false
        if let options = self.zapryOptions,!options.userId.isEmpty {
            isInit = true
        }else {
            DispatchQueue.main.async {
                ZapryUtil.makeToast("zapryOptions is not initialized", isError:true, forView: ZapryUtil.keyWindow())
            }
        }
        return isInit
    }
    
    public func clearCache() {
        self.payTypeWithCache = .none
    }
    
    public func getUserIdFromOptions() -> String {
        guard let option = self.zapryOptions else {
            self.checkPrivateKeyInit(method: "getUserIdFromOptions")
            return ""
        }
        if option.userId.isEmpty {
            self.checkPrivateKeyInit(method: "getUserIdFromOptions")
        }
        return option.userId
    }
    
    public func setPayAuth(params:[String:Any]?,isSaveWallet:Bool,completion:@escaping (Bool,String)->Void) {
        guard self.checkOptions() else {
            self.checkPrivateKeyInit(method: "setPayAuth")
            completion(false,"")
            return
        }
        let type:Int =  params?["type"] as? Int ?? 0
        let password:String = params?["payPassword"] as? String ?? ""
        if !password.isEmpty {
            ZapryWalletManager.shared.setPayPasword(password: password)
        }
        
        if type == 1 || type == 2 {
            ZapryDeviceInfo.authByFaceIDOrTouchID {[weak self] error in
                if let err = error {
                    //出错了
                    let errorTip = "setPayAuth failed:\(err.code),\(err.localizedDescription)"
                    completion(false,errorTip)
                }else {
                    //成功
                    self?.transferToSecurityStore(type: type,isSave: isSaveWallet,password:password)
                    completion(true,"")
                }
            }
        }else if type == 3 {
            if !password.isEmpty {
                //shytodo 保存密码md5
                ZapryWalletManager.setCurrentPayPasswordMD5(payPasswordMD5: password.md5)
                self.transferToSecurityStore(type: type,isSave: isSaveWallet,password:password)
                completion(true,"")
            } else {
                completion(false,"setPayAuth failed:\(type)")
            }
        }else {
            completion(false,"")
        }
    }
    
    public func setMultiWalletInfo(params:[String:Any]?,completion:@escaping (Bool,String)->Void) {
        guard let params = params,
              let wallet = params["wallet"] as? [String: Any],
            let mnemonic = params["mnemonic"] as? String else {
            completion(false,"")
            return
        }
        var backupID:String?
        if let extData = params["extData"] as? [String: Any], let buID = extData["backupId"] as? String {
            backupID = buID
        }
        let password = ZapryWalletManager.shared.getPayPassword()
        self.setWalletInfo(mnemonic: mnemonic, wallet: wallet, password: password, backupID: backupID) {[weak self] result, msg in
            ZapryWalletManager.shared.clearPayPasword()
            completion(result,msg)
        }
    }

    
    private func setWalletInfo(mnemonic:String,wallet:[String: Any],password:String,backupID:String?,completion:@escaping (Bool,String)->Void) {
        guard self.checkOptions() else {
            self.checkPrivateKeyInit(method: "setWalletInfo")
            return
        }
        ZapryWalletManager.setMultiWalletInfo(mnemonic:mnemonic, wallet: wallet, password: password, backupID: backupID) { result, msg in
            completion(result,msg)
        }
    }
    
    public func checkPay(params:[String:Any],completion:@escaping (Int,String,String) -> Void) {
        let payType = params["payType"] as? Int ?? 1
        var payModel = ZapryPayModel()
        //转账
        if let data = params["data"] as? [String:Any] {
            let tempModel = ZapryJSONUtil.dictionaryToModel(data, ZapryPayModel.self)
            if let model = tempModel {
                payModel = model
            }
        }
        let sceneType = ZaprySceneType(rawValue:payType) ?? .none
        let verificationType = ZapryPrivateKeyHelper.shared.getPaymentVerificationMethod()
        let whiteList:[ZaprySceneType] = [.CloudBackup,.PayPasswordAuth,.CreateWallet,.AddNewChain]
        if verificationType == .password && (whiteList.contains(sceneType)) {
            ZapryWalletManager.shared.setPayPasword(password: payModel.payPassword)
        }
        self.checkBeforePayOrSet(hasSet: false, sceneType:sceneType,payModel:payModel) { action, result, error in
            completion(action,result,error)
        }
    }
    
    public func checkBeforeSet(completion:@escaping (Int,String,String) -> Void) {
        self.checkBeforePayOrSet(hasSet: true,completion: completion)
    }
    
    func checkBeforePayOrSet(hasSet:Bool,forceSetPassworld:Bool = false, sceneType:ZaprySceneType = .none,payModel:ZapryPayModel = ZapryPayModel(),completion:@escaping (Int,String,String) -> Void) {
        guard self.checkOptions() else {
            self.checkPrivateKeyInit(method: "checkBeforePayOrSet")
            return
        }
        let verificationType = ZapryPrivateKeyHelper.shared.getPaymentVerificationMethod()
        let window = ZapryUtil.keyWindow()
        if verificationType.rawValue <= 0 {
            //获取异常的处理
            self.showAlertByNoSetVerifityType(hasSet: hasSet, forceSetPassworld:forceSetPassworld, sceneType:sceneType, payModel: payModel, completion: completion)
        } else {
            if verificationType == .faceID || verificationType == .touchID {
                let type = ZapryDeviceInfo.getDeviceBiometricType()
                if type == .none || type == .denyBiometry || type == .lock {
                    ZapryUtil.makeToast(ZapryNSI18n.shared.biometric_disabler_tip, isError: true, forView: window)
                    NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"DeviceBiometric enable"])
                    return
                }
            }
            if hasSet {
                completion(ZapryResultAction.success.rawValue,"","")
                return
            }
            
            if ZapryWalletManager.getWalletAddress().count <= 0 && sceneType != .CreateWallet {
                completion(ZapryResultAction.close.rawValue,"","")
                NotificationCenter.default.post(name:Notification.Name("GOTOWALLET"), object:nil, userInfo: nil)
                return
            }
            
            if sceneListWithoutUI.contains(sceneType) {
                if verificationType == .password {
                    //签证只有faceId或者touchId是无界面的，，密码是有界面的
                    if sceneType != .Sign  {
                        self.getWalletThatAuthByPayPassword(sceneType: sceneType, payModel: payModel, completion: completion)
                        return
                    }
                } else {
                    //由于解绑之后不会删除支付验证方式的存储，创建钱包的时候需要特殊处理
                    if sceneType == .CreateWallet {
                        ZapryDeviceInfo.authByFaceIDOrTouchID { e in
                            if e != nil {
                                completion(ZapryResultAction.fail.rawValue,"","")
                            } else {
                                completion(ZapryResultAction.success.rawValue,"","")
                            }
                        }
                    }else {
                        self.authByFaceIDOrTouchID(sceneType:sceneType, payModel: payModel, completion: completion)
                    }
                    return
                }
            }
            
            var popUp = ZapryPayVerificationView.checkPayPopupView(payScene: sceneType)
            if popUp == nil {
               popUp = ZapryPayVerificationView(frame: .zero, mode: verificationType, payScene: sceneType,payModel: payModel)
                popUp?.finishedCallback = { resultType,result,error in
                    completion(resultType.rawValue,result,error)
                }
            }
            popUp?.show()
        }
    }
    
    public func deleteWallet(isAdd:Bool = false) {
        guard self.checkOptions() else {
            self.checkPrivateKeyInit(method: "deleteWallet")
            return
        }
        ZapryWalletManager.deleteWallet()
        //shytodo 原业务没有
        if !isAdd {
//            ZapryPrivateKeyHelper.shared.savePaymentVerificationMethod(type: .none)
        }
    }
    
    public func deleteNewWallet() {
        guard self.checkOptions() else {
            self.checkPrivateKeyInit(method: "deleteNewWallet")
            return
        }
        ZapryWalletManager.deleteNewWallet()
    }
    
    public func getMultiAddress() -> [String: String]? {
        return ZapryWalletManager.getMultiAddress()
    }
    
    public func getWalletAddress(chainCode: String = "2000000") -> String {
        let address = ZapryWalletManager.getWalletAddress(chainCode: chainCode)
        return address
    }

    public func currentWalletHasBackup() -> Bool { 
        guard let options = self.zapryOptions,!options.userId.isEmpty else {
            return false
        }
        return ZapryWalletManager.currentWalletHasBackup()
    }
    
    public func getCurrentBackupID() -> String? {
        return ZapryWalletManager.getCurrentBackupID()
    }
    public func setCurrentBackupID(backupID: String) {
        ZapryWalletManager.setCurrentBackupID(backupID: backupID)
    }
    
    public func backupCurrentWallet(params:[String:Any]?) -> String? {
        guard let params = params else {
            return nil
        }
        guard let psw = params["password"] as? String else {
            return nil
        }
        let password = ZapryWalletManager.shared.getPayPassword()
        let result = ZapryWalletManager.backupCurrentWallet(backupPassword: psw, password:password)
        ZapryWalletManager.shared.clearPayPasword()
        return result
    }
    
    public func getWalletInfo(params:[String:Any]?) -> [String: Any]? {
        guard let params = params,
                let chainCode = params["chainCode"] as? String else {
            return nil
        }
        let password = ZapryWalletManager.shared.getPayPassword()
        let result = ZapryWalletManager.getWalletInfo(chainCode: chainCode, password:password)
        ZapryWalletManager.shared.clearPayPasword()
        return result
    }
    
    public func getPaymentVerificationMethod(isCache:Bool = true) -> ZapryDeviceBiometricType {
        guard let option = self.zapryOptions,!option.userId.isEmpty else {
            self.checkPrivateKeyInit(method: "getPaymentVerificationMethod")
            return .none
        }
        if isCache && self.payTypeWithCache.rawValue > 0 {
            return self.payTypeWithCache
        }
        let saveKey: String = String.init(format: "PaymentVerificationType_%@", option.userId)
        var type = 0
        
        if let value = ZapryUtil.readObject(key:saveKey) {
            if let valueInt = value as? Int {
                type = valueInt
                
            } else if let valueNumber = value as? NSNumber {
                type = valueNumber.intValue
                
            } else if let valueString = value as? String {
                type = Int(valueString) ?? 0
                
            } else if let valueNSString = value as? NSString {
                type = Int(valueNSString.intValue)
                
            } else {
                type =  Int("\(value)") ?? 0
                
                NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"getPaymentVerificationMethod git value is object ; saveKey=\(saveKey) ; type = \(type)"])
            }

        } else {
            let integerValue = UserDefaults.standard.integer(forKey: saveKey)
            NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"getPaymentVerificationMethod git \(ZapryUtil.readObject(key:saveKey) ?? ""):\(saveKey); integerValue = \(integerValue)"])
        }
        return ZapryDeviceBiometricType(rawValue: type) ?? .none
    }
    
    public func checkPrivateKeyInit(method:String) {
        NotificationCenter.default.post(name:Notification.Name("CheckPrivateKeyInitNotification"), object: nil, userInfo: ["location":method])
    }
    
    public func savePaymentVerificationMethod(type:ZapryDeviceBiometricType) {
        guard self.checkOptions() else {
            self.checkPrivateKeyInit(method: "savePaymentVerificationMethod")
            return
        }
         let saveKey: String = String.init(format: "PaymentVerificationType_%@", self.zapryOptions?.userId ?? "")
         NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"savePaymentVerificationMethod \(saveKey):\(type.rawValue)"])
         
         UserDefaults.standard.set(type.rawValue, forKey: saveKey)
         UserDefaults.standard.synchronize()
        self.payTypeWithCache = type
    }
    
    public func getUndecryptWalletsThatAuthByBackupPassword() -> Dictionary<String,String> {
        let ret = ZaprySecurityStore.getUndecryptWalletsThatAuthByBackupPassword()
        return ret
    }
    
    public func getWalletThatAuthByBackupPassword(backupID: String, backupPassword: String) throws -> String {
        let result = try ZaprySecurityStore.getWalletThatAuthByBackupPassword(backupID: backupID, backupPassword: backupPassword)
        return result
    }
    
    public func deleteWalletThatAuthByBackupPassword(backupID: String) -> Bool {
        let result = ZaprySecurityStore.deleteWalletThatAuthByBackupPassword(backupID: backupID)
        return result
    }
    
    public func getWalletThatAuthByBiometric() -> String? {
        let result = ZaprySecurityStore.getWalletThatAuthByBiometric()
        return result
    }
    
    public func getWalletThatAuthByPayPassword(payPassword: String) -> String? {
        let result = ZaprySecurityStore.getWalletThatAuthByPayPassword(payPassword: payPassword)
        return result
    }
    
    public func decrypt(encryptValue: String, key: String) -> String? {
        let result = ZaprySecurityStore.decrypt(encryptValue: encryptValue, key: key)
        return result
    }
    
    public func deleteWalletThatAuthByBiometric() -> Bool {
        let result = ZaprySecurityStore.deleteWalletThatAuthByBiometric()
        return result
    }
    
    private func showAlertByNoSetVerifityType(hasSet:Bool,forceSetPassworld:Bool,sceneType:ZaprySceneType,payModel:ZapryPayModel,completion:@escaping (Int,String,String) -> Void) {
        let type = ZapryDeviceInfo.getDeviceBiometricType()
        let hasPassword = forceSetPassworld ? true : (type == .none || type == .denyBiometry || type == .lock)
        
        let title = hasPassword ? ZapryNSI18n.shared.biometric_setting_pay_password : ZapryNSI18n.shared.biometric_setting_biometric
        let content = hasPassword ? ZapryNSI18n.shared.biometric_setting_pay_password_subtitle : ZapryNSI18n.shared.biometric_setting_biometric_subtitle
        var subContent:String = ""
        let hasNoWallet = ZapryWalletManager.getWalletAddress().count <= 0
        if hasNoWallet {
            subContent = hasPassword ? ZapryNSI18n.shared.biometric_setting_pay_password_desc : ZapryNSI18n.shared.biometric_setting_biometric_desc 
        }
        let alertView = ZapryAlertView(title:title, content:content,subContent:subContent, confirmText:ZapryNSI18n.shared.common_skip, cancelText:ZapryNSI18n.shared.common_skip)
        alertView.confirmHandle = { v in
            let verifyType = hasPassword ? 3 : ZapryDeviceInfo.getDeviceBiometricType().rawValue
            NotificationCenter.default.post(name: NSNotification.Name("GOTO_SET_VERFICATION_TYPE"), object: nil, userInfo: ["type":verifyType])
            completion(ZapryResultAction.close.rawValue,"","")
        }
        alertView.cancelHandle = { v in
            if !hasPassword {
                self.checkBeforePayOrSet(hasSet: hasSet,forceSetPassworld: true,sceneType: sceneType,payModel: payModel, completion: completion)
                return
            }
            completion(ZapryResultAction.close.rawValue,"","")
        }
        alertView.show()
    }
    
    private func getWalletThatAuthByPayPassword(sceneType:ZaprySceneType,payModel:ZapryPayModel,completion:@escaping (Int,String,String) -> Void) {
        var pas:String?
        if (ZaprySecurityStore.hasWalletThatAuthByPayPassword() ) {
            pas = ZaprySecurityStore.getWalletThatAuthByPayPassword(payPassword:payModel.payPassword)
        }else {
            //shytodo 保存密码MD5
            NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"use password MD5 verification"])
            if let md5 = ZapryWalletManager.getCurrentPayPasswordMD5() {
                if ( payModel.payPassword.md5 == md5 ) { // 验证通过
                    completion(ZapryResultAction.success.rawValue,"","")
                } else {
                    NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"password verification failed"])
                    completion(ZapryResultAction.fail.rawValue,"","")
                }
            } else {
                completion(ZapryResultAction.success.rawValue,"","")
            }
            return
        }
        if let value = pas,!value.isEmpty {
            completion(ZapryResultAction.success.rawValue,value,"")
        }else {
            completion(ZapryResultAction.fail.rawValue,"","")
        }
    }
    
    private func authByFaceIDOrTouchID(sceneType:ZaprySceneType,payModel:ZapryPayModel,completion:@escaping (Int,String,String) -> Void) {
        let model = ZapryWalletManager.getWalletModel(password: "")
        if let model = model {
            let walletJson = ZapryWalletManager.modelToStr(model:model) ?? ""
            completion(ZapryResultAction.success.rawValue,walletJson,"")
        }else {
            completion(ZapryResultAction.fail.rawValue,"","")
        }
    }
    
    private func transferToSecurityStore(type:Int,isSave:Bool,password:String) {
        let verificationType = ZapryDeviceBiometricType(rawValue: type) ?? .none
        if isSave {
            let success = self.transferToSecurityStoreIfNeeded(targetType: verificationType,walletModel: nil)
            if success {
                ZapryPrivateKeyHelper.shared.savePaymentVerificationMethod(type: verificationType)
            }else {
                //保存不成功
                print("switch \(verificationType.rawValue) Verification fail:save keychain failed")
                ZapryUtil.makeToast("Set failed",isError:true, forView: ZapryUtil.keyWindow())
            }
        }
    }
    
    public func transferToSecurityStoreIfNeeded(targetType: ZapryDeviceBiometricType, walletModel:WalletModel?) -> Bool {
        let password = ZapryWalletManager.shared.getPayPassword()
        let result =  ZapryWalletManager.transferToSecurityStoreIfNeeded(targetType: targetType, walletModel: walletModel, password: password)
        return result
    }
    
    public static func stringToModel(s: String, chainCode: String = "2000000") -> WalletModel? {
        let decoder = JSONDecoder()
        guard let data = s.data(using: .utf8) else { return nil }
        guard var model = try? decoder.decode(WalletModel.self, from: data) else { return nil }
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
    
    public static func getOldWalletAddress() -> String {
        if let s = UserDefaults.standard.value(forKey: ZapryWalletManager.kMultiUdKey) as? String {
            if let model = ZapryPrivateKeyHelper.stringToModel(s: s) {
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
