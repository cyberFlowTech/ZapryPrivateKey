//
//  RNOCBridge.h
//  MIMO
//
//  Created by gaofeng on 2023/10/30.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTLog.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTBridge.h>

NS_ASSUME_NONNULL_BEGIN

#define NATIVE_TO_RN_Notify_Wallet_Jostle @"Notify_Wallet_Jostle"
#define NATIVE_Call_RN_Wallet_Recharge @"Notify_Wallet_Recharge"
#define NATIVE_Notify_Wallet_Exit @"Notify_Wallet_Exit"
#define NATIVE_Notify_Pay_Notification @"Notify_PAY_Notification"

@interface MimoReactNativeModule : RCTEventEmitter

+ (instancetype)shared;

+ (void)emitEventWithName:(NSString *)name andPayload:(NSDictionary *)payload;

@end

NS_ASSUME_NONNULL_END
