//
//  UserDefaultsUtil.swift
//  MIMO
//
//  Created by zhang shuai on 2023/4/19.
//

import Foundation
import UIKit
import HandyJSON

@objcMembers
public class UserDefaultsUtil: NSObject {
    
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
    
}
