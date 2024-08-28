//
//  ZapryPayVerificationView.swift
//  MIMO
//
//  Created by admin  on 2024/3/6.
//

import Foundation
import UIKit

public enum PaySceneType:Int {
    case none = 0
    case TransferAccount = 1 //转账
    case Transaction = 2 //合约交易
    case Sign  = 3//签名
    case checkMnemonicWord = 4 //查看助记词
    case unBind = 5//解绑
    case SendRedpacket = 6 //发送红包
    case RechargeToChangePocket = 7 //正在充值到零钱
    case WithdrawToWallet = 8 //正在提币到钱包
    case CreateWallet = 9 // 创建钱包
    case PayPasswordAuth = 10//设置生物识别的时候验证密码
    case AddNewChain = 11 //加链
    case CloudBackup = 12 //保存
    case VerificationBiometic = 14 //设置密码 验证生物识别
}

public enum TronSignType:Int {
    case Sign = 1
    case Transfer = 2
    case Approve = 3
}

public class ZapryPayVerificationView:UIView {
    let tagPrex = 200000
    
    var finishedCallback: ((CheckAction,String,String) -> Void)?
    
    var verificationModel:VerificationType
    var paySceneType:PaySceneType
    var payModel:PayModel = PayModel()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame:CGRect,mode:VerificationType,payScene:PaySceneType,payModel:PayModel = PayModel()) {
        self.verificationModel = mode
        self.paySceneType = payScene
        self.payModel = payModel
        super.init(frame: frame)
        self.setupSubviews()
    }
    
    // MARK: - event
    
    @objc func keyboardWillShow(notifi: Notification) {
        
        self.isHidden = false
        
        let keyboardRect:CGRect = notifi.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        
        let ty = keyboardRect.size.height
        UIView.animate(withDuration: 0.25) {
            self.backgroundColor = UIColor(hexString: "#000000", alpha: 0.8)
            let contentRect = self.contentView.frame
            self.contentView.frame = CGRectMake(CGRectGetMinX(contentRect),CGRectGetHeight(UIScreen.main.bounds) - ty + 20.0 - CGRectGetHeight(contentRect), CGRectGetWidth(contentRect), CGRectGetHeight(contentRect))
            self.contentView.superview?.layoutIfNeeded()
        } completion: { finished in
           
        }
    }
    
    @objc func keyboardWillHide() {
        UIView.animate(withDuration: 0.25) {
            self.backgroundColor = UIColor.clear
            let contentRect = self.contentView.frame
            self.contentView.frame = CGRectMake(CGRectGetMinX(contentRect),CGRectGetHeight(UIScreen.main.bounds) + 295.0, CGRectGetWidth(contentRect), CGRectGetHeight(contentRect))
            self.contentView.superview?.layoutIfNeeded()
        } completion: { finished in
            self.isHidden = true
            self.removeFromSuperview()
        }
    }

    @objc func bgTap() {
        self.finishedCallback?(.close,"","")
        self.hide()
    }
    
    @objc func doNothingTap() {}
    
    @objc func btnClickVerificate(btn:UITapGestureRecognizer) {
        self.verificationResult(password: "")
    }
    
    // MARK: -private
    
    func addNoti() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name(rawValue: "UIKeyboardWillShowNotification"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name(rawValue: "UIKeyboardWillHideNotification"),
                                               object: nil)
    }
    
    func removeNoti() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func show() {
        self.reloadData()
    }
    
    func hide() {
        if self.verificationModel != .password {
            self.removeFromSuperview()
        }else {
            UIApplication.shared.sendAction( #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil )
        }
        self.removeNoti()
    }
    
    @objc func closeBtnClickCallBack(sender:UIButton) {
        self.finishedCallback?(.close,"","")
        self.hide()
    }
    
    func reloadData() {
        var isNFT:Bool = false
        var title = ""
        if self.verificationModel == .password {
            title = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_input_pay_password")
        }else if self.verificationModel == .faceID {
            title = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_pay_face")
        }else if self.verificationModel == .touchID {
            title = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_fingerprint_verify")
        }
        self.titleLabel.text = title
        var payAmount = self.payModel.amount
        let token:[String:Any]? = self.payModel.token
        var payUnit:String = token?["token"] as? String ?? "ETMP"
        if self.paySceneType == .SendRedpacket {
            title = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_sending_crypto")
        } else if self.paySceneType == .TransferAccount {
            let addressToStr = self.getShowAddress(address: self.payModel.to)
            isNFT = self.payModel.nftTokenId.count > 0
            let nick = self.payModel.nick.isEmpty ? "" :  "[\(self.payModel.nick)]"
            if isNFT {
                title = String(format:ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_transferring_nft"),nick,addressToStr)
                payUnit = (self.payModel.nftName)
                payAmount = ""
                let tokenId = self.getShowAddress(address:self.payModel.nftTokenId,minCount:16,preNum: 5,sufNum: 5)
                self.nftTokenIdLabel.text = tokenId.count > 0 ? "#\(tokenId)" : tokenId
            }else {
                title = String(format:ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_transferring"),nick,addressToStr)
            }
            
        }else if self.paySceneType == .RechargeToChangePocket {
            title =  ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_top_up")
        }else if self.paySceneType == .WithdrawToWallet {
            title = String(format:ZapryUtil.shared.getZapryLocalizedStringForKey(key: "withdraw_wallet_tip"), self.payModel.to)
        }else if self.paySceneType == .Transaction {
            title = String(format:ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_transferring"),"",self.payModel.to)
            payUnit = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_contract_trading")
            payAmount = ""
        }else if self.paySceneType == .Sign {
            let isTronSign = self.payModel.signType > 0
            if isTronSign {
                if self.payModel.signType == 3 {
                    payUnit = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_contract_trading")
                    title = self.payModel.signData["contract"] as? String ?? ""
                } else if self.payModel.signType == 2 {
                    payUnit = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_contract_trading")
                    title = self.payModel.signData["to"] as? String ?? ""
                }else{
                    title = self.payModel.signData["to"] as? String ?? ""
                    payUnit = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "signature_message_sign")
                }
                if !title.isEmpty {
                    title = String(format:ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_transferring"),"",title)
                }
            } else {
                if !self.payModel.to.isEmpty {
                    title = String(format:ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_transferring"),"",self.payModel.to)
                }else {
                    title = ""
                }
                payUnit = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "signature_message_sign")
            }
            payAmount = ""
        }
        var contentHeight = self.verificationModel == .password ? ((isNFT ? 320 : 294) + 20) : (536.0 + (isNFT ? 26 : 0))
        let payDescRect = self.payDescLabel.frame
        let paynumRect = self.payNumLabel.frame
        if !title.isEmpty {
            self.payDescLabel.text = title
            self.payDescLabel.frame = CGRectMake(CGRectGetMinX(payDescRect), CGRectGetMinY(payDescRect),CGRectGetWidth(payDescRect), 30.0)

            self.payNumLabel.frame = CGRectMake(CGRectGetMinX(paynumRect),CGRectGetMaxY(self.payDescLabel.frame) + 8.0, CGRectGetWidth(paynumRect), CGRectGetHeight(paynumRect))
        }else {
            self.payDescLabel.text = ""
            self.payDescLabel.frame = CGRectMake(CGRectGetMinX(payDescRect), CGRectGetMinY(payDescRect),CGRectGetWidth(payDescRect), 0.0)
            
            self.payNumLabel.frame = CGRectMake(CGRectGetMinX(paynumRect),CGRectGetMaxY(self.payDescLabel.frame), CGRectGetWidth(paynumRect), CGRectGetHeight(paynumRect))
            
            contentHeight = self.verificationModel == .password ? ((isNFT ? 320 : 294) + 20 - 31) : (536.0 - 31 + (isNFT ? 26 : 0))
        }
        let contentViewRect = self.contentView.frame
        self.contentView.frame = CGRectMake(CGRectGetMinX(contentViewRect), CGRectGetMinY(contentViewRect), CGRectGetWidth(contentViewRect),contentHeight)
        self.setPayNumLabelAttribe(amount: payAmount, str: payUnit)
    
        if self.verificationModel == .faceID || self.verificationModel == .touchID {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: DispatchWorkItem(block: {
                self.verificationResult(password: "")
            }))
        }
    }
    
    func setPayNumLabelAttribe(amount:String,str:String) {
        
        let amountText = NSMutableAttributedString.init(string:"")
        let amountAttribe = NSMutableAttributedString(string: amount, attributes: [.foregroundColor : UIColor(hex: "#323232"),.font:UIFont.boldSystemFont(ofSize: 42)])
        amountText.append(amountAttribe)
        
        let etmpText = NSMutableAttributedString(string: str, attributes: [.foregroundColor:UIColor(hex: "#323232"),.font:UIFont.systemFont(ofSize: 19.0)])
        
        amountText.append(etmpText)
        self.payNumLabel.attributedText = amountText
    }
    
    func verificationResult(password:String) {
        let pas:String?
        if self.verificationModel == .password {
            pas = ZaprySecurityStore.getWalletThatAuthByPayPassword(payPassword:password)
        }else {
            self.touchIdIV.isUserInteractionEnabled = false
            pas = ZaprySecurityStore.getWalletThatAuthByBiometric()
            self.touchIdIV.isUserInteractionEnabled = true
        }
        
        if let value = pas,!value.isEmpty {
            //成功
            self.finishedCallback?(.success,value, "")
            self.hide()
        }else {
            //失败
            if self.verificationModel == .password {
                self.codeUnitView.verifyErrorAction()
            }
            let window = ZapryUtil.keyWindow()
            ZapryUtil.makeToast(ZapryUtil.shared.getZapryLocalizedStringForKey(key: "verification_failed_tip"),isError: true, forView:window)
        }
    }
    
    func getShowAddress(address:String,minCount:Int = 10,preNum:Int = 4,sufNum:Int = 6) -> String {
        if address.count <= minCount {
            return address
        }
        
        let str = "\(address.prefix(preNum))...\(address.suffix(sufNum))";
        return str
    }
    
    class func checkPayPopupView(payScene:PaySceneType) -> ZapryPayVerificationView? {
        let window = ZapryUtil.keyWindow()
        if let view = window.viewWithTag(200000) as? ZapryPayVerificationView,view.paySceneType == payScene,!view.isHidden {
            return view
        }
        return nil
    }
        
    func setupSubviews() {
        let window = ZapryUtil.keyWindow()
        if let view = window.viewWithTag(tagPrex) {
            view.removeFromSuperview()
        }
        
        self.tag = tagPrex
        window.addSubview(self)
        let mainRect = UIScreen.main.bounds
        self.frame = mainRect
        
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(bgTap))
        self.addGestureRecognizer(bgTap)
        
        let contentHeight = self.verificationModel == .password ? (294.0 + 20) : 536.0
        self.contentView.frame = CGRect(x: 0, y:CGRectGetHeight(mainRect) - contentHeight, width: CGRectGetWidth(mainRect), height: contentHeight)
        if self.verificationModel != .password {
            self.backgroundColor = UIColor(hexString: "#000000", alpha: 0.8)
        }
        self.addSubview(self.contentView)

        let contentTap = UITapGestureRecognizer(target: self, action: #selector(doNothingTap))
        self.contentView.addGestureRecognizer(contentTap)
        
        
        self.contentView.addSubview(self.closeBtn)
        self.closeBtn.frame = CGRectMake(15.0, 16.0, 24.0, 24.0)
        
        self.contentView.addSubview(self.titleLabel)
        let titleWidth = CGRectGetWidth(mainRect) - 56.0
        self.titleLabel.frame = CGRectMake((CGRectGetWidth(mainRect) - titleWidth)/2.0, 16.0,CGRectGetWidth(mainRect) - 56.0, 20.0)
        
        self.contentView.addSubview(self.payDescLabel)
        self.payDescLabel.frame = CGRectMake(15.0, 68.0, CGRectGetWidth(mainRect) - 30.0, 30.0)
        self.contentView.addSubview(self.payNumLabel)
        self.payNumLabel.frame = CGRectMake(CGRectGetMinX(self.payDescLabel.frame), CGRectGetMaxY(self.payDescLabel.frame) + 8.0 ,CGRectGetWidth(self.payDescLabel.frame), 30.0)
        let isNFT = self.payModel.nftTokenId.count > 0
        if isNFT {
            self.contentView.addSubview(self.nftTokenIdLabel)
            self.nftTokenIdLabel.frame = CGRectMake(CGRectGetMinX(self.payDescLabel.frame), CGRectGetMaxY(self.payNumLabel.frame) + 8.0,CGRectGetWidth(self.payDescLabel.frame), 30.0)
        }

        self.contentView.addSubview(self.bottomLineView)
        self.bottomLineView.frame = CGRectMake(15.0, CGRectGetMaxY((isNFT ? self.nftTokenIdLabel.frame : self.payNumLabel.frame)) + 18.0, CGRectGetWidth(mainRect) - 15.0*2.0, 0.5)
        
        self.contentView.addSubview(self.paymentModeLabel)
        self.paymentModeLabel.frame = CGRectMake(CGRectGetMinX(self.bottomLineView.frame), CGRectGetMaxY(self.bottomLineView.frame) + 12.0, CGRectGetWidth(self.bottomLineView.frame) - 100.0, 30.0)
        
        self.contentView.addSubview(self.walletLabel)
        self.walletLabel.frame = CGRectMake(CGRectGetMaxX(self.bottomLineView.frame) - 100.0, CGRectGetMinY(self.paymentModeLabel.frame), 100.0, 30.0)
        
        if self.verificationModel == .password {
            self.addNoti()
            self.codeUnitView.addViewTo(contentView)
            let itemHeight = (CGRectGetWidth(UIScreen.main.bounds) - 15.0*2.0 - 5*8.0)/6.0
            self.codeUnitView.frame = CGRectMake(CGRectGetMinX(self.bottomLineView.frame),CGRectGetMaxY(self.walletLabel.frame) + 18.0, CGRectGetWidth(self.bottomLineView.frame),itemHeight)
        }else  {
            let ivWidth = 56.0
            self.contentView.addSubview(self.touchIdIV)
            let isTouch = self.verificationModel == .touchID
            let imageName = isTouch ? "pay_touch_icon" :  "login_faceid"
            let image = ZapryUtil.shared.getBundleImage(imageName: imageName)
            self.touchIdIV.image = image
            let logoWidth = 56.0
            let height = (CGRectGetHeight(self.contentView.frame) - CGRectGetMaxY(self.paymentModeLabel.frame) - logoWidth)/2.0
            self.touchIdIV.frame = CGRectMake((CGRectGetWidth(mainRect) - ivWidth) / 2.0,CGRectGetMaxY(self.paymentModeLabel.frame) + height, logoWidth, logoWidth)
        }
    }
    
    lazy var closeBtn:UIButton = {
        let btn = UIButton(type: .custom)
        let image = ZapryUtil.shared.getBundleImage(imageName: "post_light_gray_close")
        btn.setImage(image, for: .normal)
        btn.addTarget(self, action:#selector(closeBtnClickCallBack(sender:)), for: .touchUpInside)
        return btn
    }()
    lazy var codeUnitView:ZapryCodeUnit = {
        let kScreenWidth = UIScreen.main.bounds.size.width
        let itemHeight = (kScreenWidth - 15.0*2.0 - 5*8.0)/6.0
        let view = ZapryCodeUnit(frame: CGRectMake(0, 0, kScreenWidth - 15.0*2.0, itemHeight), delegate: self)
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor(hex: "#323232")
        label.textAlignment = .center
        return label
    }()
    
    lazy var payDescLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor(hex: "#323232")
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    lazy var payNumLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.textColor = UIColor(hex: "#323232")
        label.textAlignment = .center
        return label
    }()
    
    lazy var nftTokenIdLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19)
        label.textColor = UIColor(hex: "#323232")
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    lazy var bottomLineView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#E3E5E8")
        
        return view
    }()
    
    lazy var paymentModeLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#6C737F")
        label.text = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_pay_method")
        return label
    }()
    
    lazy var walletLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#6C737F")
        label.text = ZapryUtil.shared.getZapryLocalizedStringForKey(key: "mine_wallet")
        label.textAlignment = .right
        return label
    }()
    
    lazy var touchIdIV:UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled(false)
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(btnClickVerificate(btn:))))
        return iv
    }()
    
    lazy var contentView:UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()
    
}

extension ZapryPayVerificationView:ZapryCodeUnitDelegate {
    
    public func attributesOfCodeUnit(for codeUnit: ZapryCodeUnit) -> KeenCodeUnitAttributes {
        var attr = KeenCodeUnitAttributes()
        attr.style = .splitborder
        attr.isSingleAlive = true
        attr.itemSpacing = 8
        attr.itemPadding = 0
        attr.backgroundColor = UIColor(hex:"#EEF0F4")
        attr.cornerRadius = 15
        attr.borderWidth = 0
        attr.isSecureTextEntry = true
        return attr
    }
    
    public func codeUnit(_ codeUnit: ZapryCodeUnit, codeText: String, complete: Bool) {
        if complete {
            self.verificationResult(password: codeText)
        }
        
    }
}
