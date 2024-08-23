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
        let btnOffsetY = 20.0
    
        self.view.addSubview(self.createWalletBtn)
        self.createWalletBtn.frame = CGRectMake(0.0,150.0 ,CGRectGetWidth(mainRect), btnHeight)
        
        self.view.addSubview(self.clickBtn)
        self.clickBtn.frame = CGRect(x: 0.0, y:CGRectGetMaxY(self.createWalletBtn.frame) + btnOffsetY, width:CGRectGetWidth(mainRect), height: btnHeight)
        
        self.view.addSubview(self.deleteWalletBtn)
        self.deleteWalletBtn.frame = CGRectMake(0.0, CGRectGetMaxY(self.clickBtn.frame) + btnOffsetY, CGRectGetWidth(mainRect), btnHeight)
        
        NotificationCenter.default.addObserver(self, selector:#selector(removeRNVC(notif: )), name:NSNotification.Name("REMOVERNVC"), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gotoVerifictionTypeVC(notif:)), name: NSNotification.Name("GOTO_SET_VERFICATION_TYPE"), object: nil)
        
        UserConfig.shared.userId = "844097"
        ZapryUtil.shared.setPreferredLanguage(preLan: "zh-Hans")
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
                RNManager.shared.pushToSetPayAuth(vc: self, type: VerificationType(rawValue: type) ?? .password, params: ["from":"Setting"])
            }
        }
    }
    
    @objc func clickBtnCallBack(sender:UIButton) {
        guard let _ = WalletManager.getMultiAddress() else {
            MMToast.makeToast("未创建钱包",isError: true, forView:ZapryUtil.keyWindow())
            return 
        }
        let payModel = PayModel()
        payModel.amount = "-0.03"
        payModel.token = ["token":"ETH"]
        let payScene:PaySceneType = .RechargeToChangePocket
        payModel.signType = payScene.rawValue
        let chainCode = "20000"
        payModel.chainCode = chainCode
        PaymentManager.shared.checkBeforePay(sceneType: payScene.rawValue, payModel: payModel) { action, result, error in
            print("action:\(action),result:\(result),error:\(error)")
            let isSuccess = action == 1
            MMToast.makeToast(isSuccess ? "Successful" : "Failed", isError:!isSuccess, forView: ZapryUtil.keyWindow())
        }
    }
    
    @objc func createWalletBtnCallBack(sender:UIButton) {
        if let _ = WalletManager.getMultiAddress() {
            MMToast.makeToast("钱包已创建",isError: true, forView:ZapryUtil.keyWindow())
            return
        }
        let vc = RNManager.shared.getVC(page: .wallet)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func deleteWalletBtnCallBack(sender:UIButton) {
        guard let _ = WalletManager.getMultiAddress() else {
            MMToast.makeToast("未创建钱包",isError: true, forView:ZapryUtil.keyWindow())
            return 
        }
        WalletManager.deleteWallet()
        UserConfig.save(type: .none)
        RNManager.shared.closeRNVC()
        MMToast.makeToast("Delete Successful", isError:false, forView: ZapryUtil.keyWindow())
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
