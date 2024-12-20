//
//  ZapryUtil.swift
//  ZapryWalletSdk
//
//  Created by admin  on 2024/8/20.
//

import Foundation
import HandyJSON

public enum ZaprySDKLanguange:Int {
    case en = 0
    case zh_Hans = 1
    case zh_Hant = 2
    case vi = 3
    case ko = 4
    case ja = 5
    case mn = 6
    case th = 7
}

public class ZapryUtil {
    public static let shared = ZapryUtil()
    public static let bundle = Bundle(path: Bundle.init(for:ZapryUtil.self).path(forResource: "ZapryPrivateKey", ofType: "bundle") ?? "")
    var languageBundle:Bundle?
    let supportedLanguages = ["zh-Hans","en","zh-Hant","vi","ko","ja","mn","th"]
    
    func getBundleImage(imageName:String) -> UIImage? {
        if imageName.isEmpty {
            return nil
        }
        var scale = Int(UIScreen.main.scale)
        if scale < 2 {
            scale = 2
        }
        if scale > 3 {
            scale = 3
        }
        let targetName = "\(imageName)@\(scale)x"
        let path = Self.bundle?.path(forResource:targetName, ofType:"png") ?? ""
        let image = UIImage(contentsOfFile: path)
        return image
    }
    
    public func getZapryLocalizedStringForKey(key:String) -> String {
        let value =  self.languageBundle?.localizedString(forKey: key, value:"", table: nil)
        return value ?? ""
    }
    
    func setPreferredLanguage(lan:ZaprySDKLanguange) {
        let usedLanguage = self.getLanguageFileName(lan: lan)
        self.languageBundle = Bundle.init(path: Self.bundle?.path(forResource:usedLanguage, ofType: "lproj") ?? "")
    }
    
    private func getLanguageFileName(lan:ZaprySDKLanguange) -> String {
        var languange:String = "en"
        if lan == .zh_Hans {
            languange = "zh-Hans"
        } else if lan == .zh_Hant {
            languange = "zh-Hant"
        } else if lan == .vi {
            languange = "vi"
        } else if lan == .ko {
            languange = "ko"
        } else if lan == .ja {
            languange = "ja"
        } else if lan == .mn {
            languange = "mn"
        } else if lan == .th {
            languange = "th"
        }
        return languange
    }
    
    public class func keyWindow() -> UIWindow {
       if #available(iOS 15.0, *) {
           let keyWindow = UIApplication.shared.connectedScenes
               .map({ $0 as? UIWindowScene })
               .compactMap({ $0 })
               .first?.windows.first ?? UIWindow()
           return keyWindow
       } else {
           let keyWindow = UIApplication.shared.windows.first ?? UIWindow()
           return keyWindow
       }
    }
    
    class func sizeOfText(text: String, font: UIFont, maximumWidth: CGFloat) -> CGSize {
        return text.boundingRect(with:CGSize(width: maximumWidth, height:CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [.font : font], context:nil).size
    }
    class func sizeOfTextByWidth(text: String, font: UIFont, maximumHeight: CGFloat) -> CGSize {
        return text.boundingRect(with:CGSize(width: CGFloat(MAXFLOAT), height:maximumHeight), options: .usesLineFragmentOrigin, attributes: [.font : font], context:nil).size
    }
    
    public class func saveObject(object: Any?, key: String) {
         let defaults = UserDefaults.standard
         if object == nil {
             defaults.set(nil, forKey: key)
         } else if object is NSNumber {
             defaults.set(object, forKey: key)
         } else if object is String {
             defaults.set(object, forKey: key)
         } else if object is [String : Any] {
             defaults.set(object, forKey: key)
         } else if object is [Any] {
             defaults.set(object, forKey: key)
         } else {
             let dic: [String : Any] = (object as! HandyJSON).toJSON()!
             defaults.set(dic, forKey: key)
         }
         
         defaults.synchronize()
     }
     
    public class func readObject(key: String) -> Any? {
         let defaults = UserDefaults.standard
         let dic = defaults.object(forKey: key)
         return dic
     }
     
    public class func removeObject(keys: [String]) {
         let defaults = UserDefaults.standard
         for key in keys {
             defaults.removeObject(forKey: key)
             defaults.synchronize()
         }
     }
    
    /// 显示Toast(居中，显示时可以点击其他地方)
    @objc public class func makeToast(_ message: String?,isError:Bool,forView view: UIView?) {
        DispatchQueue.main.async {
            var style = ZapryToastStyle()
            style.imageSize = CGSize(width: 32.0, height: 32.0)
            style.cornerRadius = 18.0
            style.messageFont = UIFont.systemFont(ofSize: 15)
            style.titleColor = UIColor(hex: "#FFFFFF")
            style.verticalPadding = 24.0
            style.horizontalPadding = 24.0
            style.isHorizontal = false
            let imageName = isError ? "toast_error_icon" : "toast_ right_icon"
            let image = ZapryUtil.shared.getBundleImage(imageName: imageName)
            NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"toast : \(message ?? "")"])
            view?.zapryMakeToast(message, position: .center, image:image,style:style)
        }
    }
    
    @objc public class func makeToastWithoutState(_ message: String?, forView view: UIView?) {
        DispatchQueue.main.async {
            view?.zapryMakeToast(message, position: .center)
        }
    }

    @objc public class func hideToast(view: UIView?) {
        DispatchQueue.main.async {
            view?.zapryHideToast()
        }
    }
    
    //字体
    class func kZapryRegularFont(size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Regular", size: size)!
    }

    class func kZapryMediumFont(size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Medium", size: size)!
    }

    class func kZaprySemiboldFont(size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Semibold", size: size)!
    }
    
    class func kZapryDINBoldFont(size:CGFloat) -> UIFont {
        if let font = UIFont(name: "DIN-Bold", size: size) {
            return font
        }
        return kZapryMediumFont(size: size)
    }

    class func kZapryDINMediumFont(size:CGFloat) -> UIFont {
        if let font = UIFont(name: "DIN-Medium", size: size) {
            return font
        }
        return kZaprySemiboldFont(size: size)
    }
    
}
