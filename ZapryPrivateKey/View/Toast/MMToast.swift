//
//  MMToast.swift
//  MIMO
//
//  Created by zhang shuai on 2023/4/14.
//

import UIKit

public class MMToast: NSObject {

    /// 显示Toast(居中，显示时可以点击其他地方)
    @objc public class func makeToast(_ message: String?,isError:Bool,forView view: UIView?) {
        DispatchQueue.main.async {
            var style = ToastStyle()
            style.imageSize = CGSize(width: 32.0, height: 32.0)
            style.cornerRadius = 18.0
            style.messageFont = UIFont.systemFont(ofSize: 15)
            style.titleColor = UIColor(hex: "#FFFFFF")
            style.verticalPadding = 24.0
            style.horizontalPadding = 24.0
            style.isHorizontal = false
            let imageName = isError ? "toast_error_icon" : "toast_ right_icon"
            let image = ZapryUtil.shared.getBundleImage(imageName: imageName)
            view?.makeToast(message, position: .center, image:image,style:style)
        }
    }
    
    @objc public class func makeToastWithoutState(_ message: String?, forView view: UIView?) {
        DispatchQueue.main.async {
            view?.makeToast(message, position: .center)
        }
    }

    @objc public class func hideToast(view: UIView?) {
        DispatchQueue.main.async {
            view?.hideToast()
        }
    }
}
