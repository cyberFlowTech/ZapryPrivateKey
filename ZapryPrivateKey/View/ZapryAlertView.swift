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
        kKeyWindow.addSubview(self)
        self.frame = kKeyWindow.frame
        
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(bgTap))
        self.addGestureRecognizer(bgTap)

        self.addSubview(self.contentView)

        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.text = self.titleText ?? ""
        let titleWidth = CGRectGetWidth(self.frame) - (43.5 + 32.0)*2.0
        var titleHeight = 0.0
        var titlePosY = 0.0
        if let title = self.titleText,!title.isEmpty {
            titlePosY = 24.0
            titleHeight = ZapryUtil.sizeOfText(text: self.titleText ?? "", font: UIFont.boldSystemFont(ofSize: 16), maximumWidth: titleWidth).height
        }
        self.titleLabel.frame = CGRectMake(43.5, titlePosY,titleWidth, titleHeight)
        
        self.contentView.addSubview(self.contentLabel)
        self.contentLabel.text = self.contentText
        let contentWidth = titleWidth
        var contentHeight = 0.0
        var contentPosY = CGRectGetMaxY(self.titleLabel.frame)
        if let conent = self.contentText,!conent.isEmpty {
            contentHeight = ZapryUtil.sizeOfText(text:conent, font: UIFont.systemFont(ofSize: 14), maximumWidth: contentWidth).height
            contentPosY = contentPosY + 22.0
        }
        self.contentLabel.frame = CGRectMake(CGRectGetMinX(self.titleLabel.frame),contentPosY,contentWidth, contentHeight)
        
        self.subContentLabel.text = self.subContentText
        self.contentView.addSubview(self.subContentLabel)
        let subContentWidth = titleWidth
        var subContentHeight = 0.0
        var subContentPosY = CGRectGetMaxY(self.contentLabel.frame)
        if let subContent = self.subContentText,!subContent.isEmpty {
            subContentHeight = ZapryUtil.sizeOfText(text:subContent, font: UIFont.systemFont(ofSize: 13), maximumWidth: subContentWidth).height
            subContentPosY = subContentPosY + 10.0
        }
        self.subContentLabel.frame = CGRectMake(CGRectGetMinX(self.titleLabel.frame), subContentPosY, subContentWidth, subContentHeight)
        
        let width = CGRectGetWidth(self.frame) - 32.0*2.0
        
        let btnPosY = CGRectGetMaxY(self.subContentLabel.frame) + 27.0
        let btnWidth = (width - 10.0 - 24.5*2.0)/2.0
        let btnHeight = 44.0
        self.contentView.addSubview(self.cancelButton)
        self.cancelButton.frame = CGRectMake(24.5, btnPosY, btnWidth, btnHeight)
        
        self.contentView.addSubview(self.confirmButton)
        self.confirmButton.frame = CGRectMake(CGRectGetMaxX(self.cancelButton.frame) + 10.0, btnPosY, btnWidth, btnHeight)
        
        let height = CGRectGetMaxY(self.cancelButton.frame) + 30.0
        let posY = (CGRectGetHeight(self.frame) - height) / 2.0
        self.contentView.frame = CGRectMake(32.0, posY, width, height)
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
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    lazy var contentLabel:UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hex: "#2F3237")
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    lazy var subContentLabel:UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hex: "#999999")
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 13)
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
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var cancelButton:UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 22
        btn.backgroundColor = UIColor(hex: "#F2F3F5")
        btn.setTitle(self.cancelText, for: .normal)
        btn.setTitleColor(UIColor(hex: "#767E8B"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        return btn
    }()

}
