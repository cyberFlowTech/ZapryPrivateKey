//
//  PaymentManager.swift
//  MIMO
//
//  Created by admin  on 2024/3/7.
//

import Foundation
import UIKit
import HandyJSON

public enum CheckAction:Int {
    case none = 0 // 跳过
    case success = 1 //成功
    case fail = 2 //失败
    case set = 3 //设置
    case close = 4 //关闭
}

@objcMembers
public class PayModel:NSObject,HandyJSON {
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
public class PaymentManager: NSObject {
    public var CompletionHandle: ((_ type:Int) -> Void)?
    public static let shared = PaymentManager()
    public static let ERROR_CODE_BIOMETRIC_FAILED:Int = -10001
    public static let ERROR_CODE_PASSWORD_FAILED:Int = -10002
    private var sceneListWithoutUI:[PaySceneType] = [.unBind,.checkMnemonicWord,.CreateWallet,.VerificationBiometic,.PayPasswordAuth,.AddNewChain,.CloudBackup,.Sign]
    
    public func setPayAuth(type:Int,password:String,isSaveWallet:Bool,completion:@escaping (Bool,String)->Void) {
        if type == 1 || type == 2 {
            DeviceInfo.authByFaceIDOrTouchID {[weak self] error in
                if let err = error {
                    //出错了
                    let errorTip = "setPayAuth failed:\(err.code),\(err.localizedDescription)"
                    completion(false,errorTip)
                }else {
                    //成功
                    self?.transferToSecurityStore(type: type,isSave: isSaveWallet,password: "")
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
        }
    }
    
    func transferToSecurityStore(type:Int,isSave:Bool,password:String) {
        let verificationType = VerificationType(rawValue: type) ?? .none
        if isSave {
            let success = WalletManager.transferToSecurityStoreIfNeeded(targetType: verificationType,walletModel: nil,password: password)
            if success {
                UserConfig.save(type:verificationType)
            }else {
                //保存不成功
                print("switch \(verificationType.rawValue) Verification fail:save keychain failed")
                MMToast.makeToast("Set failed",isError:true, forView: ZapryUtil.keyWindow())
            }
        }
    }
    
    public func checkBeforeSet(completion:@escaping (Int,String,String) -> Void) {
        self.checkBeforePayOrSet(hasSet: true,completion: completion)
    }
    
    public func checkBeforePay(sceneType:Int,payModel:PayModel, completion:@escaping (Int,String,String) -> Void) {
        let type = PaySceneType(rawValue: sceneType) ?? .none
        self.checkBeforePayOrSet(hasSet: false, sceneType:type,payModel:payModel, completion: completion)
    }
    
    func checkBeforePayOrSet(hasSet:Bool,forceSetPassworld:Bool = false, sceneType:PaySceneType = .none,payModel:PayModel = PayModel(),completion:@escaping (Int,String,String) -> Void) {
        let verificationType = UserConfig.read()
        let window = ZapryUtil.keyWindow()
        if verificationType.rawValue <= 0 {
            //获取异常的处理
            self.showAlertByNoSetVerifityType(hasSet: hasSet, forceSetPassworld:forceSetPassworld, sceneType:sceneType, payModel: payModel, completion: completion)
        } else {
            if verificationType == .faceID || verificationType == .touchID {
                let type = DeviceInfo.getDeviceBiometricType()
                if type == .none || type == .denyBiometry || type == .lock {
                    MMToast.makeToast(ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_disabler_tip"), isError: true, forView: window)
                    return
                }
            }
            if hasSet {
                completion(CheckAction.success.rawValue,"","")
                return
            }
            
            if WalletManager.getWalletAddress().count <= 0 && sceneType != .CreateWallet {
                completion(CheckAction.close.rawValue,"","")
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
            
            var popUp = PayVerificationPopupView.checkPayPopupView(payScene: sceneType)
            if popUp == nil {
               popUp = PayVerificationPopupView(frame: .zero, mode: verificationType, payScene: sceneType,payModel: payModel)
                popUp?.finishedCallback = { resultType,result,error in
                    completion(resultType.rawValue,result,error)
                }
            }
            popUp?.show()
        }
    }
    
    public func getPrivateKey(json: String, chainCode: String) -> String {
        var privateKey = ""
        let code = WalletManager.getChainCode(chainCode: chainCode)
        if let model = WalletManager.stringToModel(s:json, chainCode: code) {
            privateKey = model.accountPrivateKey
        }
        return privateKey
    }
    
    public func getWalletAddress(chainCode: String) -> String {
        let code = WalletManager.getChainCode(chainCode: chainCode)
        let address = WalletManager.getWalletAddress(chainCode: code)
        return address
    }
    
    private func showAlertByNoSetVerifityType(hasSet:Bool,forceSetPassworld:Bool,sceneType:PaySceneType,payModel:PayModel,completion:@escaping (Int,String,String) -> Void) {
        let type = DeviceInfo.getDeviceBiometricType()
        let hasPassword = forceSetPassworld ? true : (type == .none || type == .denyBiometry || type == .lock)
        
        let title = ZapryUtil.shared.getZapryLocalizedStringForKey(key:(hasPassword ? "biometric_setting_pay_password" : "biometric_setting_biometric"))
        let content = ZapryUtil.shared.getZapryLocalizedStringForKey(key: (hasPassword ? "biometric_setting_pay_password_subtitle" : "biometric_setting_biometric_subtitle"))
        var subContent:String = ""
        let hasNoWallet = WalletManager.getWalletAddress().count <= 0
        if hasNoWallet {
            subContent = ZapryUtil.shared.getZapryLocalizedStringForKey(key:(hasPassword ? "biometric_setting_pay_password_desc": "biometric_setting_biometric_desc"))
        }
        let alertView = ZaprySwiftAlertView(title:title, content:content,subContent:subContent, confirmText:ZapryUtil.shared.getZapryLocalizedStringForKey(key: "common_skip"), cancelText:ZapryUtil.shared.getZapryLocalizedStringForKey(key: "common_skip"))
        alertView.confirmHandle = { v in
            let verifyType = hasPassword ? 3 : DeviceInfo.getDeviceBiometricType().rawValue
            NotificationCenter.default.post(name: NSNotification.Name("GOTO_SET_VERFICATION_TYPE"), object: nil, userInfo: ["type":verifyType])
            completion(CheckAction.close.rawValue,"","")
        }
        alertView.cancelHandle = { v in
            if !hasPassword {
                self.checkBeforePayOrSet(hasSet: hasSet,forceSetPassworld: true,sceneType: sceneType,payModel: payModel, completion: completion)
                return
            }
            completion(CheckAction.close.rawValue,"","")
        }
        alertView.show()
    }
    
    private func getWalletThatAuthByPayPassword(sceneType:PaySceneType,payModel:PayModel,completion:@escaping (Int,String,String) -> Void) {
        var pas:String?
        if (MMSecurityStore.hasWalletThatAuthByPayPassword() ) {
            pas = MMSecurityStore.getWalletThatAuthByPayPassword(payPassword:payModel.payPassword)
        }
        if let value = pas,!value.isEmpty {
            completion(CheckAction.success.rawValue,value,"")
        }else {
            completion(CheckAction.fail.rawValue,"","")
        }
    }
    
    private func authByFaceIDOrTouchID(sceneType:PaySceneType,payModel:PayModel,completion:@escaping (Int,String,String) -> Void) {
        let model = WalletManager.getWalletModel(password: "")
        if let model = model {
            let walletJson = WalletManager.modelToStr(model:model) ?? ""
            completion(CheckAction.success.rawValue,walletJson,"")
        }else {
            completion(CheckAction.fail.rawValue,"","")
        }
    }
}
