//
//  ZapryDeviceInfo.swift
//  MIMO
//
//  Created by zhang shuai on 2023/4/7.
//

import Foundation
import UIKit
import LocalAuthentication

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
                    comp(e)
                }
            }
        }
    }
    
    public static func getDeviceBiometricType() -> VerificationType {
        var error: NSError?
        guard LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
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
