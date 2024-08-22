//
//  ZapryUtil.swift
//  ZapryWalletSdk
//
//  Created by admin  on 2024/8/20.
//

import Foundation

public class ZapryUtil {
    public static let shared = ZapryUtil()
    public static let bundle = Bundle(path: Bundle.init(for:ZapryUtil.self).path(forResource: "ZapryPrivateKey", ofType: "bundle") ?? "")
    var languageBundle:Bundle?
    let supportedLanguages = ["zh-Hans","en"]
    var preferredLanguage:String = "en"
    
    public func getBundleImage(imageName:String) -> UIImage? {
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
    
    public func setPreferredLanguage(preLan:String) {
        self.preferredLanguage = preLan
        var usedLanguage = "en"
        for language in self.supportedLanguages {
            if preLan.contains(language) {
                usedLanguage = language
                break
            }
        }
        self.languageBundle = Bundle.init(path: Self.bundle?.path(forResource:usedLanguage, ofType: "lproj") ?? "")
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
}
