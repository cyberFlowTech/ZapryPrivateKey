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
    
    public func checkBeforeSet(completion:@escaping (Int,String,String) -> Void) {
        self.checkBeforePayOrSet(hasSet: true,completion: completion)
    }
    
    public func checkBeforePay(sceneType:Int,payModel:PayModel, completion:@escaping (Int,String,String) -> Void) {
        let type = PaySceneType(rawValue: sceneType) ?? .none
        print("shy====>\(type)")
        self.checkBeforePayOrSet(hasSet: false, sceneType:type,payModel:payModel, completion: completion)
    }
    
    func checkBeforePayOrSet(hasSet:Bool,forceSetPassworld:Bool = false, sceneType:PaySceneType = .none,payModel:PayModel = PayModel(),completion:@escaping (Int,String,String) -> Void) {
        let verificationType = UserConfig.read()
        let window = ZapryUtil.keyWindow()
        if verificationType == .none || verificationType == .denyBiometry || verificationType == .lock {
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
            } else {
                if WalletManager.getWalletAddress().count <= 0 && sceneType != .CreateWallet {
                    completion(CheckAction.close.rawValue,"","")
                    //shytodo 打开钱包
                    completion(CheckAction.close.rawValue,"","")
//                    RNManager.shared.getWalletVC(navigationVC:UIViewController.getTopNavi())
                    return
                }
                
                if sceneType == .unBind || sceneType == .checkMnemonicWord || sceneType == .CreateWallet || sceneType == .VerificationBiometic || sceneType == .PayPasswordAuth || sceneType == .AddNewChain || sceneType == .CloudBackup || sceneType == .Sign {
                    var pas:String?
                    if verificationType == .password {
                        //签证只有faceId或者touchId是无界面的，，密码是有界面的
                        if sceneType != .Sign  {
                            if ( MMSecurityStore.hasWalletThatAuthByPayPassword() ) {
                                pas = MMSecurityStore.getWalletThatAuthByPayPassword(payPassword:payModel.payPassword)
                            } else {
                                if let md5 = WalletManager.getCurrentPayPasswordMD5() {
                                    if ( payModel.payPassword.md5 == md5 ) { // 验证通过
                                        completion(CheckAction.success.rawValue,"","")
                                        if ( sceneType == .CreateWallet || sceneType == .CloudBackup ) {
                                            WalletManager.shared.payPasswordForSet = payModel.payPassword
                                        }
                                    } else {
                                        completion(CheckAction.fail.rawValue,"","")
                                    }
                                } else {
                                    completion(CheckAction.success.rawValue,"","")
                                }
                                return
                            }
                            if let value = pas,!value.isEmpty {
                                if sceneType == .CloudBackup || sceneType == .PayPasswordAuth {
                                    WalletManager.shared.payPasswordForSet = payModel.payPassword;
                                }
                                completion(CheckAction.success.rawValue,value,"")
                            }else {
                                completion(CheckAction.fail.rawValue,"","")
                            }
                            return
                    }
                } else {
                    if sceneType == .checkMnemonicWord || sceneType == .AddNewChain || sceneType == .Sign {
                            let model = WalletManager.getWalletModel()
                            if let model = model {
                                let walletJson = WalletManager.modelToStr(model:model) ?? ""
                                completion(CheckAction.success.rawValue,walletJson,"")
                            }else {
                                completion(CheckAction.fail.rawValue,"","")
                            }
                        }else {
                            DeviceInfo.authByFaceIDOrTouchID { e in
                                if let e {
                                    completion(CheckAction.fail.rawValue,"","")
                                } else {
                                    completion(CheckAction.success.rawValue,"","")
                                }
                            }
                        }
                        return
                }
            } else {
                print("DQ","else sceneType = ",sceneType)
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
}
