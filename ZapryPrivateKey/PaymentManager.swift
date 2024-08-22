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
    public var payNum:String = "0.00"
    public var chainCode:String = ""
    public var nick:String = ""
    public var to:String = ""
    public var password:String = ""
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
            //没设置
            MMToast.makeToast("没设置支付验证方式", isError: true, forView: window)
            completion(CheckAction.close.rawValue,"","")
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
//                if WalletManager.getWalletAddress().count <= 0 && sceneType != .CreateWallet {
//                    completion(CheckAction.close.rawValue,"","")
//                    //shytodo 打开钱包
//                    return
//                }
                
                if sceneType == .unBind || sceneType == .checkMnemonicWord || sceneType == .CreateWallet || sceneType == .VerificationBiometic || sceneType == .PayPasswordAuth || sceneType == .AddNewChain || sceneType == .CloudBackup || sceneType == .Sign {
                    var pas:String?
                    if verificationType == .password {
                        //签证只有faceId或者touchId是无界面的，，密码是有界面的
                        if sceneType != .Sign  {
                            if ( MMSecurityStore.hasWalletThatAuthByPayPassword() ) {
                                pas = MMSecurityStore.getWalletThatAuthByPayPassword(payPassword:payModel.password)
                            } else {
                                if let md5 = WalletManager.getCurrentPayPasswordMD5() {
                                    if ( payModel.password.md5 == md5 ) { // 验证通过
                                        completion(CheckAction.success.rawValue,"","")
                                        if ( sceneType == .CreateWallet || sceneType == .CloudBackup ) {
                                            WalletManager.shared.payPasswordForSet = payModel.password
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
                                    WalletManager.shared.payPasswordForSet = payModel.password;
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
