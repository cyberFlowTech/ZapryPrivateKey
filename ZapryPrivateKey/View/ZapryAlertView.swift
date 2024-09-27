//
//  ZapryAlertView.swift
//  MIMO
//
//  Created by zhang shuai on 2023/7/6.
//

import UIKit

@objcMembers
public class ZapryAlertView: UIView {
    
    var titleText: String?
    var contentText: String?
    var confirmText: String?
    var cancelText: String?
    var subContentText: String?
    
    public var cancelHandle: ((_ alertView: ZapryAlertView) -> Void)?
    public var confirmHandle: ((_ alertView: ZapryAlertView) -> Void)?
    
   public init(title: String, content: String, confirmText: String? = "Confirm", cancelText: String? = "Cancel") {
        
        self.titleText = title
        self.contentText = content
        self.confirmText = confirmText
        self.cancelText = cancelText
        
        super.init(frame: CGRect.zero)
        
        self.setupSubviews()
    }
    
   public init(title: String, content: String,subContent:String = "", confirmText: String? = "Confirm", cancelText: String? = "Cancel") {

        self.titleText = title
        self.contentText = content
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.subContentText = subContent
        
        super.init(frame: CGRect.zero)
        
        self.setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func bgTap() {
        self.hide()
    }
    
    @objc func confirmAction() {
        self.confirmHandle?(self)
        self.hide()
    }
        
    @objc func cancelAction() {
        self.cancelHandle?(self)
        self.hide()
    }
        
    public func show() {
        self.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.backgroundColor = UIColor(hexString: "#000000", alpha: 0.7)
        } completion: { finished in
            
        }
    }
    
    public func hide() {
        self.backgroundColor = UIColor.clear
        self.isHidden = true
        self.removeFromSuperview()
    }

    func setupSubviews() {
        let kKeyWindow = ZapryUtil.keyWindow()
        let kScreenWidth = UIScreen.main.bounds.size.width
        kKeyWindow.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(bgTap))
        self.addGestureRecognizer(bgTap)
    
        self.addSubview(self.contentView)
    
        contentView.addSubview(self.titleLabel)
        self.titleLabel.text = self.titleText
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(25.0)
            make.left.equalToSuperview().offset(43.5)
            make.right.equalToSuperview().offset(-43.5)
        }
        
        self.contentView.addSubview(self.contentLabel)
        self.contentLabel.text = self.contentText
        self.contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(25)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(kScreenWidth - 25.0*2.0 - 32.0*2.0)
        }
        
        let hasSubContent = !(self.subContentText?.isEmpty ?? true)
        if hasSubContent {
            contentView.addSubview(self.subContentLabel)
            self.subContentLabel.text = self.subContentText
            self.subContentLabel.snp.makeConstraints { make in
                make.top.equalTo(self.contentLabel.snp.bottom).offset(10)
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualTo(kScreenWidth - 25.0*2.0 - 32.0*2.0)
            }
        }
        
        self.contentView.addSubview(self.confirmButton)
        self.confirmButton.setTitle(self.confirmText, for: .normal)
        self.confirmButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-25.0)
            if hasSubContent {
                make.top.equalTo(subContentLabel.snp.bottom).offset(35.0)
            }else {
                make.top.equalTo(self.contentLabel.snp.bottom).offset(35.0)
            }
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-30)
        }
        
        self.contentView.addSubview(self.cancelButton)
        self.cancelButton.setTitle(self.cancelText, for: .normal)
        self.cancelButton.snp.makeConstraints { make in
            make.top.equalTo(self.confirmButton)
            make.left.equalToSuperview().offset(25.0)
            make.size.equalTo(self.confirmButton)
            make.right.equalTo(self.confirmButton.snp.left).offset(-12)
        }
        
        self.contentView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.centerY.equalToSuperview()
        }
    }
    
    lazy var contentView:UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.clipsToBounds = true
        view.layer.cornerRadius = 24
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hex:"#060606")
        label.textAlignment = .center
        label.font = ZapryUtil.kZaprySemiboldFont(size: 17)
        return label
    }()
    
    lazy var contentLabel:UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hex: "#2F3237")
        label.textAlignment = .left
        label.font = ZapryUtil.kZapryRegularFont(size: 15)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    lazy var subContentLabel:UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hex: "#999999")
        label.textAlignment = .left
        label.font = ZapryUtil.kZapryRegularFont(size: 13)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    lazy var confirmButton:UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 22
        btn.backgroundColor = UIColor(hex: "#4182FF")
        btn.setTitle(self.confirmText, for: .normal)
        btn.setTitleColor(UIColor(hex: "#FFFFFF"), for: .normal)
        btn.titleLabel?.font = ZapryUtil.kZapryRegularFont(size: 16)
        btn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var cancelButton:UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 22
        btn.backgroundColor = UIColor(hex: "#F2F3F5")
        btn.setTitle(self.cancelText, for: .normal)
        btn.setTitleColor(UIColor(hex: "#767E8B"), for: .normal)
        btn.titleLabel?.font =  ZapryUtil.kZapryRegularFont(size: 16)
        btn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        return btn
    }()

}
