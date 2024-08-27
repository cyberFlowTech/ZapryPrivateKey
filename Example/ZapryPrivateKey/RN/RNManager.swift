//
//  RNManager.swift
//  MIMO
//
//  Created by gaofeng on 2023/10/26.
//

import Foundation
import React
import UIKit
import ZapryPrivateKey

enum RNPage: String {
    case backend = "Backend"
    case wallet = "Home"
    case transfer = "Transfer" //旧版本转账
    case sendAmount = "SendAmount" //新版转账
    case receiveDetail = "ReceiveDetail"
    case transferDetail = "TransferDetail"
    case FaceIDSetting = "FaceIDSetting"
    case TouchIDSetting = "TouchIDSetting"
    case PayPasswordSetting = "PayPasswordSetting"
    case BackupHome = "BackupHome"
    case BackupRecover = "BackupRecover"
    case OpenBioMetricBoot = "OpenBiometricBoot"
    case PayPasswordAuth = "PayPasswordAuth"
    case Swap = "Swap"
    case Browser = "Browser"
    case PointReward = "Point_reward"
    case tokenAddCustom = "TokenAddCustom"
	case approveDetail = "ApproveDetail"
}

enum RNActionName: String {
    case scan = "scan" // 打开扫一扫
    case saveImage = "saveImage" // 保存图片
    case rectContacts = "rectContacts" // 最近联系人
    case close = "close" // 关闭当前页面
    case getWalletByChainCode = "getWalletByChainCode"
    case setMultiWalletInfo = "setMultiWalletInfo"
    case removePrivateKey = "removePrivateKey"
    case removeLoadingView = "removeLoadingView"
    case recharge = "recharge"
    case toDappBrowser = "toDappBrowser"
    case putLogs = "putLogs"
    case setPayAuth = "setPayAuth"
    case requestPayAuth = "requestPayAuth"
    case requestBackupCloud = "requestBackupCloud"
    case getCloudBackupList = "getCloudBackupList"
    case getCurrentCloudBackup = "getCurrentCloudBackup"
    case recoverFromCloud = "recoverFromCloud"
    case removeCurrentBackup = "removeCurrentBackup"
    case goBackGestureEnabled = "goBackGestureEnabled"
    case getImageUrlCachePath = "getImageUrlCachePath"    
    case putStatistics = "putStatistics"
    case shareTokenByRN = "shareTokenByRN"
    case sendDone = "sendDone"
    case sendError = "sendError"
    case FeedbackGenerator = "FeedbackGenerator"
}

class RNBaseViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        if let parentVC = parent {
            
        }else {
            print("RN:willMove")
        }
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        if let parentVC = parent {
            
        }else {
            //关闭RN发送事件
            MimoReactNativeModule.emitEvent(withName: "Notify_Wallet_Exit", andPayload: [:])
        }
    }
}

@objcMembers
class RNManager: NSObject, RCTBridgeModule, RCTBridgeDelegate {
    var rnInitialProperties:[String: Any]?
    var rnDidShowContent:Bool = false
    var bridge:RCTBridge?
    var completionHandle:((Bool,String,NSError?)->Void)?
    var transferToSSCompletion:((VerificationType)->Void)?
    var rnVCManager:RNBaseViewController?
    //shytodo 临时暂放这里，后期需要去掉
    var payPasswordForSet: String?
    
    static func moduleName() -> String! {
        "MimoWalletRnapp"
    }

    static let shared = RNManager()
    
    func getMimoBridge() -> RCTBridge {
        if (self.bridge == nil) {
            self.bridge = RCTBridge(delegate: self)
        }
        return self.bridge!
    }
    
    @objc func rnContentDidAppear(noti:Notification) {
        self.rnDidShowContent = true
        if let properties = self.rnInitialProperties {
            if let rnRootView = self.rnVCManager?.view as? RCTRootView {
                rnRootView.appProperties = properties
            }
        }
    }
    
   public func getVC(page: RNPage, params: [String: Any] = [:]) -> UIViewController {
        //没有设置支付验证，需要跳转到设置去处理
        let json = "{\"version\":\"88888888\",\"newcomer\":true,\"api\":\"i_1681907958\",\"user\":{\"remarks\":\"\",\"nick\":\"MIMO3071\",\"open_fun\":false,\"nft_name\":\"\",\"age\":\"\",\"isTodayFirst\":false,\"is_friend\":0,\"flag\":0,\"u_conf\":{\"friend_verify\":0,\"cover\":\"https:\\/\\/infras-test.S3.ap-southeast-1.amazonaws.com\\/\\/571D6E36-9E35-4AB4-8B83-13C959C311F2.png\",\"strange_msg\":false,\"dynamic_show\":1,\"notice_type\":0,\"lan\":\"zh_CN\",\"nft_set\":0,\"is_search\":1,\"asset\":1},\"user_type\":70,\"active_time\":\"\",\"pay_pwd\":\"\",\"user_id\":\"844097\",\"sex\":\"0\",\"is_general\":0,\"level\":\"\",\"is_focus\":0,\"origin_avatar\":\"https:\\/\\/infras-test.S3.ap-southeast-1.amazonaws.com\\/\\/5C297570-C1B7-4DBC-9ACA-F742C3BF3BD6.png\",\"ipfs_host\":\"\",\"sessid\":\"\",\"status\":\"\",\"is_pwd\":1,\"isRegister\":false,\"address\":\"0x970752d063cb75f10c5b304b4de4cfc61c6eec92\",\"avatar\":\"https:\\/\\/infras-test.S3.ap-southeast-1.amazonaws.com\\/\\/5C297570-C1B7-4DBC-9ACA-F742C3BF3BD6.png\",\"is_block\":0,\"is_fission\":\"\",\"focus\":3,\"reg_time\":\"0\",\"in_book\":0,\"fans\":1,\"hasWallet\":false,\"block\":0,\"phrase\":\"\",\"desc\":\"来咯女t狗狗哈哈哈哈太开心我现在还以为他就是个笑话来的吗哈拉哈河解决不知道自己到底有没有事情想要想要自己解决任何办法就是没有理由想好起来也没有任何时候不要因为不在意自己做自己的选择和借口去面对任何一位不同阶段或者别人认为别人做事情做不到位事情发生了一些不好事情要不就是不要\"},\"uuid\":\"D2C3900A-FDD3-475B-AA35-E261CEF59B61\",\"supportLangs\":[\"en\",\"ko\",\"zh-Hans\",\"zh-Hant\",\"vi\",\"ja\",\"mn\",\"th\"],\"lan\":\"zh_CN\",\"sign_time\":\"1724308391\",\"user_id\":\"844097\",\"sessid\":\"c4ca72724336ba0d098bf39ee337f499\",\"version_code\":\"123456\",\"env\":\"development\",\"securityKey\":\"*&^%as#$@T@%\",\"authType\":-1,\"baseUrl\":\"https:\\/\\/mimo-test.mimo.immo\\/\",\"screen\":\"Home\",\"supportAuthType\":3}"
       
       var params = JSONUtil.stringToDic(json)
       let biometricType = DeviceInfo.getDeviceBiometricType()
       params?["supportAuthType"] = (biometricType == .none || biometricType == .denyBiometry || biometricType == .lock) ? VerificationType.password.rawValue : biometricType.rawValue
        if page != .backend {
            self.rnInitialProperties = params
        }
        
        if(self.rnVCManager == nil) {
            NotificationCenter.default.addObserver(self, selector: #selector(rnContentDidAppear(noti:)), name:.RCTContentDidAppear, object: nil)
            let rootView = RCTRootView(bridge:self.getMimoBridge(), moduleName: "MimoWalletRnapp", initialProperties: params)
            let vc = RNBaseViewController()
            vc.view = rootView
            self.rnVCManager = vc
        }
        
       if let rnRootView = self.rnVCManager?.view as? RCTRootView,page != .backend,self.rnDidShowContent {
           rnRootView.appProperties = self.rnInitialProperties
       }
       return self.rnVCManager!
    }
    
    
    @objc(sourceURLForBridge:) func sourceURL(for bridge: RCTBridge) -> URL! {
        #if DEBUG
//        if let str = UserDefaultsUtil.readObject(key: "RN_URL_STR") as? String,str.count > 0 {
//            return URL(string:str)!
//        }else {
//            return URL(string: "http://192.168.50.144:8081/index.bundle?platform=ios")!
            return Bundle.main.url(forResource: "main", withExtension: "jsbundle") ?? URL(string: "")!
//        }
//            return Bundle.main.url(forResource: "main", withExtension: "jsbundle") ?? URL(string: "")!
        #else
            return Bundle.main.url(forResource: "main", withExtension: "jsbundle") ?? URL(string: "")!
        #endif
    }
    
    func pushToSetPayAuth(vc: UIViewController?, type:VerificationType, params: [String: Any] = [:]) {
        var page:RNPage = .PayPasswordSetting
        var dict:[String:Any] = [String:Any]()
        if type == .faceID || type == .touchID {
            page = .OpenBioMetricBoot
        }else if type == .password {
            page = .PayPasswordSetting
        }
        dict["supportAuthType"] = type.rawValue
        dict = dict.merging(params) { first, _ in
            return first
        }
        let rnVC = self.getVC(page:page, params: dict)
        vc?.navigationController?.pushViewController(rnVC, animated: true)
    }
    
    func closeRNVC() {
        if let rnRootView = self.rnVCManager?.view as? RCTRootView {
            rnRootView.bridge.invalidate()
        }
        self.rnVCManager = nil
        self.rnInitialProperties = nil
        self.rnDidShowContent = false
        self.bridge = nil
    }
}

extension RNManager {
    @objc class func rnCall(action: String,
                            params: String?,
                            resolver: RCTPromiseResolveBlock?,
                            reject: RCTPromiseRejectBlock?) {
        guard let action = RNActionName(rawValue: action) else {
            return
        }
        print("shy==>action:\(action),\(params)")
        let data = JSONUtil.stringToDic(params)
        DispatchQueue.main.async {
            RNManager.shared.rnAction(action: action,
                                      param1: "",
                                      params: data,
                                      resolver: resolver,
                                      reject: reject)
        }
    }
    func rnAction(action: RNActionName,
                  param1: String,
                  params: [String: Any]?,
                  resolver: RCTPromiseResolveBlock?,
                  reject: RCTPromiseRejectBlock?) {
        switch action {
        case .close:
            NotificationCenter.default.post(name: Notification.Name("REMOVERNVC"), object: nil, userInfo: nil)
            break
        case .setPayAuth:
            self.setPayAuth(params: params, resolver: resolver, reject: reject)
            break
        case .goBackGestureEnabled:
            self.goBackGestureEnabled(params: params, resolver: resolver, reject: reject)
            break
        case .requestPayAuth:
            self.requestPayAuth(params: params, resolver: resolver, reject: reject)
            break
        case .setMultiWalletInfo:
            self.setMultiWalletInfo(params: params, resolver: resolver, reject: reject)
        default:
            print("")
        }
    }
    
    func requestPayAuth(params:[String:Any]?,
                        resolver: RCTPromiseResolveBlock?,
                        reject: RCTPromiseRejectBlock?) {
        guard let params = params else {
            reject?("-1", "", nil)
            return
        }
        let payType = params["payType"] as? Int ?? 1
        var payModel = PayModel()
        //转账
        if let data = params["data"] as? [String:Any] {
            let tempModel = JSONUtil.dictionaryToModel(data, PayModel.self)
            if let model = tempModel {
                payModel = model
            }
        }
        let sceneType = PaySceneType(rawValue:payType) ?? .none
        let verificationType = UserConfig.read()
        let whiteList:[PaySceneType] = [.CloudBackup,.PayPasswordAuth,.CreateWallet]
        if verificationType == .password && (whiteList.contains(sceneType)) {
            RNManager.shared.payPasswordForSet = payModel.payPassword
        }
        PaymentManager.shared.checkBeforePay(sceneType:sceneType.rawValue, payModel: payModel) {[weak self] action,result, error in
            let checkAction = CheckAction(rawValue: action)
            if checkAction == .success {
                if sceneType == .checkMnemonicWord {
                    var dict = [String:Any]()
                    let model = WalletManager.stringToModel(s: result)
                    dict["mnemonic"] = model?.mnemonic
                    resolver?(dict)
                }else if sceneType == .PayPasswordAuth {
                    self?.completionHandle?(true,"",nil)
                    resolver?(true)
                } else {
                    let chainCode = payModel.chainCode
                    if !chainCode.isEmpty{
                        let model = WalletManager.stringToModel(s: result,chainCode: chainCode)
                        var dict = [String:Any]()
                        dict["mnemonic"] = model?.mnemonic ?? ""
                        if chainCode == "-1" {
                            //shytodo 保存支付密码需求去掉
                            if !payModel.payPassword.isEmpty {
                                RNManager.shared.payPasswordForSet = payModel.payPassword
                            }
                            let walletDict = JSONUtil.stringToDic(model?.multiWalletInfo)
                            dict["wallet"] = walletDict
                        }else {
                            dict["wallet"] = ["address":model?.accountAddress ?? "" ,
                                              "privateKey":model?.accountPrivateKey ?? ""]
                        }
                        resolver?(dict)
                    }else {
                        resolver?(true)
                    }
                }
            }else {
                if sceneType == .PayPasswordAuth {
                    let errTip = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "verification_failed_tip")
                    let err = NSError(domain: "Error", code: PaymentManager.ERROR_CODE_PASSWORD_FAILED, userInfo:[NSLocalizedDescriptionKey:errTip])
                    self?.completionHandle?(false,"",err)
                }
                var code:Int = -1
                if verificationType == .faceID || verificationType == .touchID {
                    code = PaymentManager.ERROR_CODE_BIOMETRIC_FAILED
                }else if verificationType == .password {
                    code = PaymentManager.ERROR_CODE_PASSWORD_FAILED
                }
                reject?(String(code),"",nil)
            }
        }
    }
    
    private func setMultiWalletInfo(params: [String: Any]?,
                                    resolver: RCTPromiseResolveBlock?,
                                    reject: RCTPromiseRejectBlock?) {
        guard let params = params,
              let wallet = params["wallet"] as? [String: Any],
            let mnemonic = params["mnemonic"] as? String else {
            reject?("-1", "", nil)
            return
        }
        let password = RNManager.shared.payPasswordForSet ?? ""
        if ( WalletManager.saveWallet(mnemonic: mnemonic, multiWalletInfo: wallet,password:password) ) {
            if let extData = params["extData"] as? [String: Any], let backupID = extData["backupId"] as? String {
                WalletManager.setCurrentBackupID(backupID: backupID)
            }
            resolver?("0")
        } else {
            reject?("-1", "", nil)
        }
    }
    
    // 设置完成，不是验证
    func setPayAuth(params:[String:Any]?,
                    resolver: RCTPromiseResolveBlock?,
                    reject: RCTPromiseRejectBlock?) {
        let type:Int =  params?["type"] as? Int ?? 0
        if type == 1 || type == 2 {
            DeviceInfo.authByFaceIDOrTouchID {[weak self] error in
                if let err = error {
                    //出错了
                    print("setPayAuth failed:\(err.code),\(err.localizedDescription)")
                }else {
                    //成功
                    self?.transferToSecurityStore(type: type)
                    resolver?(true)
                }
            }
        }else if type == 3 {
            let payPassword = params?["payPassword"] as? String ?? ""
            if !payPassword.isEmpty {
                //shytodo 保存支付密码需求去掉
                RNManager.shared.payPasswordForSet = payPassword;
                self.transferToSecurityStore(type: type)
                resolver?(true)
            } else {
                reject?("-1", "", nil)
                print("setPayAuth failed:\(type)")
            }
        }
    }
    
    func transferToSecurityStore(type:Int) {
        let verificationType = VerificationType(rawValue: type) ?? .none
        if let completion = self.transferToSSCompletion {
            completion(verificationType)
        }else {
            let password = RNManager.shared.payPasswordForSet ?? ""
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
    
    func goBackGestureEnabled(params:[String:Any]?,resolver: RCTPromiseResolveBlock?, reject: RCTPromiseRejectBlock?) {
        let enable = params?["enabled"] as?Bool ?? true
        if let view = RNManager.shared.rnVCManager?.navigationController?.interactivePopGestureRecognizer?.view {
            if let ges = view.gestureRecognizers {
                for item in ges {
                    item.isEnabled = enable
                }
            }
        }
        RNManager.shared.rnVCManager?.view.isUserInteractionEnabled = enable
        resolver?(true)
    }

}
