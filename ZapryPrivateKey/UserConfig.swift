//
//  UserConfig.swift
//  WalletSdkProject
//
//  Created by admin  on 2024/8/19.
//

import Foundation

public enum VerificationType:Int {
    case lock = -2
    case denyBiometry = -1
    case none = 0
    case touchID = 1
    case faceID = 2
    case password = 3
}

public class UserConfig {
    public static let shared = UserConfig()
    public var userId:String = "test"
    public class func read() -> VerificationType {
        let saveKey:String  = "PaymentVerificationType_\(UserConfig.shared.userId)"
        var type = 0
        if let value = UserDefaultsUtil.readObject(key:saveKey) as? Int {
            type = value
        }
        return VerificationType(rawValue: type) ?? .none
    }
    
   public class func save(type:VerificationType) {
        let saveKey:String  = "PaymentVerificationType_\(UserConfig.shared.userId)"
        UserDefaultsUtil.saveObject(object: type.rawValue, key: saveKey)
    }
}


