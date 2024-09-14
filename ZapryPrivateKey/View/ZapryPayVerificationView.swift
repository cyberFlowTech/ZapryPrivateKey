//
//  ZapryPayVerificationView.swift
//  MIMO
//
//  Created by admin  on 2024/3/6.
//

import Foundation
import UIKit
import SnapKit

public enum ZaprySceneType:Int {
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
    case Intent = 20 //支付
}

class ZapryPayVerificationView:UIView {
    let tagPrex = 200000
    
    var finishedCallback: ((ZapryResultAction,String,String) -> Void)?
    
    var verificationModel:ZapryDeviceBiometricType
    var paySceneType:ZaprySceneType
    var payModel:ZapryPayModel = ZapryPayModel()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame:CGRect,mode:ZapryDeviceBiometricType,payScene:ZaprySceneType,payModel:ZapryPayModel = ZapryPayModel()) {
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
            self.contentView.snp.updateConstraints { make in
                make.bottom.equalTo(self.snp.bottom).offset(-ty+20)
            }
            self.contentView.superview?.layoutIfNeeded()
        } completion: { finished in
           
        }
    }
    
    @objc func keyboardWillHide() {
        UIView.animate(withDuration: 0.25) {
            self.backgroundColor = .clear
            self.contentView.snp.updateConstraints { make in
                make.bottom.equalTo(self.snp.bottom).offset(295.0)
            }
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
            title = ZapryNSI18n.shared.biometric_input_pay_password
        }else if self.verificationModel == .faceID {
            title = ZapryNSI18n.shared.biometric_pay_face
        }else if self.verificationModel == .touchID {
            title = ZapryNSI18n.shared.biometric_fingerprint_verify
        }
        self.titleLabel.text = title
        var payAmount = self.payModel.amount
        let token:[String:Any]? = self.payModel.token
        var payUnit:String = " \(token?["token"] as? String ?? "ETMP")"
        if self.paySceneType == .SendRedpacket {
            title = ZapryNSI18n.shared.biometric_sending_crypto
        } else if self.paySceneType == .TransferAccount {
            let addressToStr = self.getShowAddress(address: self.payModel.to)
            isNFT = self.payModel.nftTokenId.count > 0
            let nick = self.payModel.nick.isEmpty ? "" :  "[\(self.payModel.nick)]"
            if isNFT {
                title = String(format: ZapryNSI18n.shared.biometric_transferring_nft,nick,addressToStr)
                payUnit = (self.payModel.nftName)
                payAmount = ""
                let tokenId = self.getShowAddress(address:self.payModel.nftTokenId,minCount:16,preNum: 5,sufNum: 5)
                self.nftTokenIdLabel.text = tokenId.count > 0 ? "#\(tokenId)" : tokenId
            }else {
                title = String(format: ZapryNSI18n.shared.biometric_transferring,nick,addressToStr)
            }
            
        }else if self.paySceneType == .RechargeToChangePocket {
            title = ZapryNSI18n.shared.biometric_top_up
        }else if self.paySceneType == .WithdrawToWallet {
            let toStr = self.getShowAddress(address: self.payModel.to,minCount: 11,preNum: 6,sufNum: 5)
            title = String(format: ZapryNSI18n.shared.withdraw_wallet_tip,toStr)
        }else if self.paySceneType == .Transaction {
            let toStr = self.getShowAddress(address: self.payModel.to,minCount: 11,preNum: 6,sufNum: 5)
            title = String(format: ZapryNSI18n.shared.biometric_transferring,"",toStr)
            payUnit = ZapryNSI18n.shared.biometric_contract_trading
            payAmount = ""
        }else if self.paySceneType == .Sign {
            let isTronSign = self.payModel.signType > 0
            if isTronSign {
                if self.payModel.signType == 3 {
                    payUnit = ZapryNSI18n.shared.biometric_contract_trading
                    title = self.payModel.signData["contract"] as? String ?? ""
                } else if self.payModel.signType == 2 {
                    payUnit = ZapryNSI18n.shared.biometric_contract_trading
                    title = self.payModel.signData["to"] as? String ?? ""
                }else{
                    title = self.payModel.signData["to"] as? String ?? ""
                    payUnit = ZapryNSI18n.shared.signature_message_sign
                }
                if !title.isEmpty {
                    title = String(format: ZapryNSI18n.shared.biometric_transferring,"",title)
                }
            } else {
                if !self.payModel.to.isEmpty {
                    let toStr = self.getShowAddress(address: self.payModel.to,minCount: 11,preNum: 6,sufNum: 5)
                    title = String(format: ZapryNSI18n.shared.biometric_transferring,"",self.payModel.to)
                }else {
                    title = ""
                }
                payUnit = ZapryNSI18n.shared.signature_message_sign
            }
            payAmount = ""
        } else if (self.paySceneType == .Intent) {
            title = ZapryNSI18n.shared.flash_exchange_in_progress
        }
        var contentHeight = self.verificationModel == .password ? ((isNFT ? 320 : 294) + 20) : (536.0 + (isNFT ? 26 : 0))
        if !title.isEmpty {
            self.payDescLabel.text = title
            self.payDescLabel.snp.updateConstraints { make in
                make.height.equalTo(31)
            }
            self.payNumLabel.snp.updateConstraints { make in
                make.top.equalTo(self.payDescLabel.snp.bottom).offset(8)
            }
        }else {
            self.payDescLabel.text = ""
            self.payDescLabel.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            self.payNumLabel.snp.updateConstraints { make in
                make.top.equalTo(self.payDescLabel.snp.bottom).offset(0)
            }
            
            contentHeight = self.verificationModel == .password ? ((isNFT ? 320 : 294) + 20 - 31) : (536.0 - 31 + (isNFT ? 26 : 0))
        }
        self.contentView.snp.updateConstraints { make in
            make.height.equalTo(contentHeight)
        }
        self.setPayNumLabelAttribe(amount: payAmount, str: payUnit)
    
        if self.verificationModel == .faceID || self.verificationModel == .touchID {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: DispatchWorkItem(block: {
                self.verificationResult(password: "")
            }))
        }
    }
    
    func setPayNumLabelAttribe(amount:String,str:String) {
        let amountText = NSMutableAttributedString.init(string:"")
        let amountAttribe = NSMutableAttributedString(string: amount, attributes: [.foregroundColor : UIColor(hex: "#323232"),.font:ZapryUtil.kZapryDINBoldFont(size: 42)])
        amountText.append(amountAttribe)
        
        let etmpText = NSMutableAttributedString(string: str, attributes: [.foregroundColor:UIColor(hex: "#323232"),.font:ZapryUtil.kZapryMediumFont(size: 19)])
        
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
            ZapryUtil.makeToast(ZapryNSI18n.shared.verification_failed_tip,isError: true, forView:window)
        }
    }
    
    func getShowAddress(address:String,minCount:Int = 10,preNum:Int = 4,sufNum:Int = 6) -> String {
        if address.count <= minCount {
            return address
        }
        
        let str = "\(address.prefix(preNum))...\(address.suffix(sufNum))";
        return str
    }
    
    class func checkPayPopupView(payScene:ZaprySceneType) -> ZapryPayVerificationView? {
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
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(bgTap))
        self.addGestureRecognizer(bgTap)
        
        let contentHeight = self.verificationModel == .password ? (294.0 + 20) : 536.0
        self.contentView.frame = CGRect(x: 0, y:CGRectGetHeight(mainRect) - contentHeight, width: CGRectGetWidth(mainRect), height: contentHeight)
        if self.verificationModel != .password {
            self.backgroundColor = UIColor(hexString: "#000000", alpha: 0.8)
        }
        // 上左右圆角
        self.addSubview(contentView)
        self.contentView = contentView
        contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.snp.bottom).offset( 0)
            make.height.equalTo(contentHeight)
        }
        
        let contentTap = UITapGestureRecognizer(target: self, action: #selector(doNothingTap))
        contentView.addGestureRecognizer(contentTap)
        
        self.contentView.addSubview(self.closeBtn)
        self.closeBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15.0)
            make.top.equalToSuperview().offset(16.0)
            make.size.equalTo(CGSizeMake(24.0, 24.0))
        }
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.closeBtn)
            make.centerX.equalToSuperview()
        }
        
        self.contentView.addSubview(self.payDescLabel)
        self.payDescLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(31)
            make.top.equalToSuperview().offset(68)
        }
        
        self.contentView.addSubview(self.payNumLabel)
        self.payNumLabel.snp.makeConstraints { make in
            make.left.equalTo(self.payDescLabel)
            make.right.equalTo(self.payDescLabel)
            make.top.equalTo(self.payDescLabel.snp.bottom).offset(8)
            make.height.equalTo(48.0)
        }
        
        let isNFT = self.payModel.nftTokenId.count > 0
        if isNFT {
            self.contentView.addSubview(self.nftTokenIdLabel)
            self.nftTokenIdLabel.snp.makeConstraints { make in
                make.left.equalTo(self.payDescLabel)
                make.right.equalTo(self.payDescLabel)
                make.top.equalTo(self.payNumLabel.snp.bottom).offset(2)
            }
        }

        self.contentView.addSubview(self.bottomLineView)
        self.bottomLineView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(23.5)
            make.right.equalToSuperview().offset(-23.5)
            make.top.equalTo(isNFT ? self.nftTokenIdLabel.snp.bottom : self.payNumLabel.snp.bottom).offset(18)
            make.height.equalTo(0.5)
        }
        
        self.contentView.addSubview(self.paymentModeLabel)
        self.paymentModeLabel.snp.makeConstraints { make in
            make.left.equalTo(self.bottomLineView)
            make.right.equalTo(self.bottomLineView)
            make.top.equalTo(self.bottomLineView.snp.bottom).offset(15)
        }
        
        self.contentView.addSubview(self.walletLabel)
        self.walletLabel.snp.makeConstraints { make in
            make.right.equalTo(self.bottomLineView.snp.right)
            make.centerY.equalTo(self.paymentModeLabel)
        }
        
        if self.verificationModel == .password {
            self.addNoti()
            self.codeUnitView.addViewTo(contentView)
            self.codeUnitView.snp.makeConstraints { make in
                make.left.equalTo(self.bottomLineView)
                make.right.equalTo(self.bottomLineView)
                make.height.equalTo(54)
                make.top.equalTo(self.walletLabel.snp.bottom).offset(18)
            }
        }else  {
            self.contentView.addSubview(self.touchIdIV)
            let isTouch = self.verificationModel == .touchID
            self.touchIdIV.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(isTouch ?  -90 : -156)
                make.size.equalTo(CGSizeMake(56.0, 56.0))
            }
            let imageName = isTouch ? "pay_touch_icon" :  "login_faceid"
            let image = ZapryUtil.shared.getBundleImage(imageName: imageName)
            self.touchIdIV.image = image
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
        label.font = ZapryUtil.kZapryMediumFont(size: 17)
        label.textColor = UIColor(hex: "#323232")
        label.textAlignment = .center
        return label
    }()
    
    lazy var payDescLabel:UILabel = {
        let label = UILabel()
        label.font = ZapryUtil.kZapryRegularFont(size: 16)
        label.textColor = UIColor(hex: "#323232")
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.backgroundColor = .blue
        return label
    }()
    
    lazy var payNumLabel:UILabel = {
        let label = UILabel()
        label.font = ZapryUtil.kZapryMediumFont(size: 19)
        label.textColor = UIColor(hex: "#323232")
        label.textAlignment = .center
        label.backgroundColor = .red
        return label
    }()
    
    lazy var nftTokenIdLabel:UILabel = {
        let label = UILabel()
        label.font = ZapryUtil.kZapryMediumFont(size: 19)
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
        label.font = ZapryUtil.kZapryRegularFont(size: 14)
        label.textColor = UIColor(hex: "#6C737F")
        label.text = ZapryNSI18n.shared.biometric_pay_method
        return label
    }()
    
    lazy var walletLabel:UILabel = {
        let label = UILabel()
        label.font = ZapryUtil.kZapryRegularFont(size: 14)
        label.textColor = UIColor(hex: "#6C737F")
        label.text = ZapryNSI18n.shared.mine_wallet
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
    
    public func attributesOfCodeUnit(for codeUnit: ZapryCodeUnit) -> ZapryCodeUnitAttributes {
        var attr = ZapryCodeUnitAttributes()
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
