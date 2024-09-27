//
//  ZapryNSI18n.swift
//  ZapryPrivateKey
//
//  Created by admin  on 2024/8/28.
//

import Foundation

@objcMembers
public class ZapryNSI18n:NSObject {
   public static let shared = ZapryNSI18n()
    
   public  var biometric_disabler_tip:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_disabler_tip")
    }
    
    public var verification_failed_retry_tip:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "verification_failed_retry_tip")
    }
    
    public var biometric_dialog_subtitle:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_dialog_subtitle")
    }
    
    public var biometric_input_pay_password:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_input_pay_password")
    }
    
    public var biometric_pay_face:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_pay_face")
    }
    
    public var biometric_fingerprint_verify:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_fingerprint_verify")
    }
    
    public var biometric_sending_crypto:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_sending_crypto")
    }
    
    public var biometric_transferring_nft:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_transferring_nft")
    }
    
    public var biometric_transferring:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_transferring")
    }
    
    public var biometric_top_up:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_top_up")
    }
    
    public var withdraw_wallet_tip:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "withdraw_wallet_tip")
    }
    
    public var biometric_contract_trading:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_contract_trading")
    }
    
    public var signature_message_sign:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "signature_message_sign")
    }
    
    public var verification_failed_tip:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "verification_failed_tip")
    }
    
    public var biometric_pay_method:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_pay_method")
    }
    
    public var mine_wallet:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "mine_wallet")
    }
    
    public var common_ensure:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "common_ensure")
    }
    
    public var biometric_setting_pay_password:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_setting_pay_password")
    }
    
    public var biometric_setting_biometric:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_setting_biometric")
    }
    
    public var biometric_setting_pay_password_subtitle:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_setting_pay_password_subtitle")
    }
    
    public var biometric_setting_biometric_subtitle:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_setting_biometric_subtitle")
    }
    
    public var biometric_setting_pay_password_desc:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_setting_pay_password_desc")
    }
    
    public var biometric_setting_biometric_desc:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_setting_biometric_desc")
    }
    
    public var common_setting_now:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "common_setting_now")
    }
    
    public var common_skip:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "common_skip")
    }
    
    public var biometric_setting_save_wallet:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "biometric_setting_save_wallet")
    }
    
    public var flash_exchange_in_progress:String {
        ZapryUtil.shared.getZapryLocalizedStringForKey(key: "flash_exchange_in_progress")
    }
    
}
