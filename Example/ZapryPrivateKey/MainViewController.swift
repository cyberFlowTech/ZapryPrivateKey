//
//  MainViewController.swift
//  ZapryPrivateKey_Example
//
//  Created by admin  on 2024/8/22.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import ZapryPrivateKey

class MainViewController:UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let mainRect = UIScreen.main.bounds
        let btnHeight = 60.0
        let btnWidth = CGRectGetWidth(mainRect)
        let btnOffsetY = 20.0
    
        self.view.addSubview(self.createWalletBtn)
        self.createWalletBtn.frame = CGRectMake(0.0,150.0 ,CGRectGetWidth(mainRect), btnHeight)
        
        self.view.addSubview(self.clickBtn)
        self.clickBtn.frame = CGRect(x: 0.0, y:CGRectGetMaxY(self.createWalletBtn.frame) + btnOffsetY, width:btnWidth, height: btnHeight)
        
        self.view.addSubview(self.deleteWalletBtn)
        self.deleteWalletBtn.frame = CGRectMake(0.0, CGRectGetMaxY(self.clickBtn.frame) + btnOffsetY,btnWidth, btnHeight)
        
        NotificationCenter.default.addObserver(self, selector:#selector(removeRNVC(notif: )), name:NSNotification.Name("REMOVERNVC"), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gotoVerifictionTypeVC(notif:)), name: NSNotification.Name("GOTO_SET_VERFICATION_TYPE"), object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(gotoWalletVC(notif:)), name: Notification.Name("GOTOWALLET"), object: nil)
        
        ZapryPrivateKeyHelper.shared.initOptions(userId:"844097",language:.en)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func removeRNVC(notif:Notification) {
        self.navigationController?.popToViewController(self, animated: true)
    }
    
    @objc func gotoVerifictionTypeVC(notif:Notification) {
        if let userInfo = notif.userInfo,let type = userInfo["type"] as? Int {
            if type >= 1 {
                RNManager.shared.pushToSetPayAuth(vc: self, type: ZapryDeviceBiometricType(rawValue: type) ?? .password, params: ["from":"Setting"])
            }
        }
    }
    
    @objc func gotoWalletVC(notif:Notification) {
        
    }
    
    @objc func clickBtnCallBack(sender:UIButton) {
        
        guard let _ = ZapryPrivateKeyHelper.shared.getMultiAddress() else {
            ZapryUtil.makeToast("未创建钱包",isError: true, forView:ZapryUtil.keyWindow())
            return 
        }
        let payModel = ZapryPayModel()
        payModel.amount = "-0.03"
        payModel.token = ["token":"ETH"]
        let payScene:ZaprySceneType = .SendRedpacket
        payModel.signType = payScene.rawValue
//        let chainCode = "20000"
//        payModel.chainCode = chainCode
        ZapryPrivateKeyHelper.shared.checkBeforePay(sceneType: payScene.rawValue, payModel: payModel) { action, result, error in
            print("action:\(action),result:\(result),error:\(error)")
            let isSuccess = action == 1
            ZapryUtil.makeToast(isSuccess ? "Successful" : "Failed", isError:!isSuccess, forView: ZapryUtil.keyWindow())
        }
    }
    
    @objc func createWalletBtnCallBack(sender:UIButton) {
        if let _ = ZapryPrivateKeyHelper.shared.getMultiAddress() {
            ZapryUtil.makeToast("钱包已创建",isError: true, forView:ZapryUtil.keyWindow())
            return
        }
        let vc = RNManager.shared.getVC(page: .wallet)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func deleteWalletBtnCallBack(sender:UIButton) {
        guard let _ = ZapryPrivateKeyHelper.shared.getMultiAddress() else {
            ZapryUtil.makeToast("未创建钱包",isError: true, forView:ZapryUtil.keyWindow())
            return 
        }
        ZapryPrivateKeyHelper.shared.deleteWallet()
        RNManager.shared.closeRNVC()
        ZapryUtil.makeToast("Delete Successful", isError:false, forView: ZapryUtil.keyWindow())
    }

    lazy var clickBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .red
        btn.setTitle("Payment Verification", for: .normal)
        btn.addTarget(self, action: #selector(clickBtnCallBack(sender:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var createWalletBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .red
        btn.setTitle("Create Wallet", for: .normal)
        btn.addTarget(self, action: #selector(createWalletBtnCallBack(sender:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var deleteWalletBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .red
        btn.setTitle("Delete Wallet", for: .normal)
        btn.addTarget(self, action: #selector(deleteWalletBtnCallBack(sender:)), for: .touchUpInside)
        return btn
    }()
}
