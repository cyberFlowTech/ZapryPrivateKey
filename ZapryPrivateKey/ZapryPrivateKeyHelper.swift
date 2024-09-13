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
public class ZapryPayModel:NSObject,HandyJSON {
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
    private var sceneListWithoutUI:[ZaprySceneType] = [.unBind,.checkMnemonicWord,.CreateWallet,.VerificationBiometic,.PayPasswordAuth,.AddNewChain,.CloudBackup,.Sign]
    public var CompletionHandle: ((_ type:Int) -> Void)?
    private var payPasswordForSet:String = ""
    
    var zapryOptions:ZapryUserInfoModel?
    
    public func initOptions(userId:String,language:ZaprySDKLanguange = .en) {
        if userId.isEmpty {
            ZapryUtil.makeToast("userId is empty", isError:true, forView: ZapryUtil.keyWindow())
            return
        }
        self.zapryOptions = ZapryUserInfoModel(userId: userId,language:language)
        ZapryUtil.shared.setPreferredLanguage(lan:language)
    }
    
    public func changeLanOptions(lanaguage:ZaprySDKLanguange) {
        guard self.checkOptions() else {
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
            ZapryUtil.makeToast("zapryOptions is not initialized", isError:true, forView: ZapryUtil.keyWindow())
        }
        return isInit
    }
    
    public func getUserIdFromOptions() -> String {
        guard let option = self.zapryOptions else {
            return ""
        }
        return option.userId
    }
    
    public func setPayAuth(params:[String:Any]?,isSaveWallet:Bool,completion:@escaping (Bool,String)->Void) {
        guard self.checkOptions() else {
            completion(false,"")
            return
        }
        let type:Int =  params?["type"] as? Int ?? 0
        let password:String = params?["payPassword"] as? String ?? ""
        if !password.isEmpty {
            self.setPayPasword(password: password)
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
        let password = self.payPasswordForSet
        self.setWalletInfo(mnemonic: mnemonic, wallet: wallet, password: password, backupID: backupID) {[weak self] result, msg in
            self?.clearPayPasword()
            completion(result,msg)
        }
    }

    
    private func setWalletInfo(mnemonic:String,wallet:[String: Any],password:String,backupID:String?,completion:@escaping (Bool,String)->Void) {
        guard self.checkOptions() else {
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
        let whiteList:[ZaprySceneType] = [.CloudBackup,.PayPasswordAuth,.CreateWallet]
        if verificationType == .password && (whiteList.contains(sceneType)) {
            self.setPayPasword(password: payModel.payPassword)
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
                    self.authByFaceIDOrTouchID(sceneType:sceneType, payModel: payModel, completion: completion)
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
    
    public func deleteWallet() {
        guard self.checkOptions() else {
            return
        }
        ZapryWalletManager.deleteWallet()
        //shytodo 原业务没有
//        ZapryPrivateKeyHelper.shared.savePaymentVerificationMethod(type: .none)
    }
    
    public func deleteNewWallet() {
        guard self.checkOptions() else {
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
        let password = self.payPasswordForSet
        let result = ZapryWalletManager.backupCurrentWallet(backupPassword: psw, password:password)
        self.clearPayPasword()
        return result
    }
    
    public func getWalletInfo(params:[String:Any]?) -> [String: Any]? {
        guard let params = params,
                let chainCode = params["chainCode"] as? String else {
            return nil
        }
        let password = self.payPasswordForSet
        let result = ZapryWalletManager.getWalletInfo(chainCode: chainCode, password:password)
        self.clearPayPasword()
        return result
    }
    
    public func getPaymentVerificationMethod() -> ZapryDeviceBiometricType {
        guard let option = self.zapryOptions,!option.userId.isEmpty else {
            return .none
        }
        let saveKey:String  = "PaymentVerificationType_\(option.userId)"
        var type = 0
        if let value = ZapryUtil.readObject(key:saveKey) as? Int {
            type = value
        }
        return ZapryDeviceBiometricType(rawValue: type) ?? .none
    }
    
    public func savePaymentVerificationMethod(type:ZapryDeviceBiometricType) {
       guard self.checkOptions() else {
           return
       }
       let saveKey:String  = "PaymentVerificationType_\(self.zapryOptions?.userId ?? "")"
       ZapryUtil.saveObject(object: type.rawValue, key: saveKey)
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
        let password = self.payPasswordForSet
        let result =  ZapryWalletManager.transferToSecurityStoreIfNeeded(targetType: targetType, walletModel: walletModel, password: password)
        return result
    }
    
    private func clearPayPasword() {
        self.payPasswordForSet = ""
    }
    
    private func setPayPasword(password:String) {
        self.payPasswordForSet = password
    }
}
