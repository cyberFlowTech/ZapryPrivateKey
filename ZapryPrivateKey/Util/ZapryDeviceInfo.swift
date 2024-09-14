//
//  ZapryDeviceInfo.swift
//  MIMO
//
//  Created by zhang shuai on 2023/4/7.
//

import Foundation
import UIKit
import LocalAuthentication

public enum ZapryDeviceBiometricType:Int {
    case lock = -2
    case denyBiometry = -1
    case none = 0
    case touchID = 1
    case faceID = 2
    case password = 3
}

public class ZapryDeviceInfo {
    
    public static var idfv: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    public static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    public static func testAuthByFaceIDOrTouchID() -> NSError? {
        var error: NSError?
        let result = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if ( result == false ) {
            if let e = error {
                NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"local auth error : debug \(e.debugDescription) [\(e.code)]"])
                return e
            }
            return NSError()
        }
        return nil
    }
    
    public static func authByFaceIDOrTouchID(comp: @escaping (NSError?) -> Void) {
        let test = ZapryDeviceInfo.testAuthByFaceIDOrTouchID()
        if ( test != nil ) {
            DispatchQueue.main.async {
                comp(test)
            }
            return
        }
        Task {
            let context = LAContext()
            context.localizedFallbackTitle = ZapryNSI18n.shared.verification_failed_retry_tip
            
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason:ZapryNSI18n.shared.biometric_dialog_subtitle)
                DispatchQueue.main.async {
                    comp(nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    let e = error as NSError
                    NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":"local auth error : debug \(e.debugDescription) [\(e.code)]"])
                    comp(e)
                }
            }
        }
    }
    
    public static func getDeviceBiometricType() -> ZapryDeviceBiometricType {
        var error: NSError?
        guard LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let errorLog = ZapryJSONUtil.dicToJsonString(dic: error?.userInfo ?? [:]) ?? ""
            if !errorLog.isEmpty {
                let errorStr = "device Owner Authentication:code:\(error?.code ?? 0),error:\(errorLog)"
                NotificationCenter.default.post(name: ZapryPrivateKeyHelper.ZAPRY_REPROT_NOTIFICATION, object: nil, userInfo: ["error":errorLog])
            }
            if error?.code == -8 {
                return .lock
            }
            return .denyBiometry
        }
        switch LAContext().biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        default:
            return .none
        }
    }
    
    public static func getSafeDistanceBottom() -> CGFloat {
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let window = windowScene.windows.first else { return 0 }
        return window.safeAreaInsets.bottom
    }
}
