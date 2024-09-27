//
//  WalletSdkRNModule.h
//  MIMO
//
//  Created by admin  on 2024/2/20.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

NS_ASSUME_NONNULL_BEGIN

#define NATIVE_Notify_Send_Transaction @"Notify_Send_Transaction"
#define NATIVE_Notify_Get_Balance @"Notify_Get_Balance"
#define NATIVE_Notify_Sign @"Notify_Sign"

@interface WalletSdkRNModule : RCTEventEmitter

+ (instancetype)shared;

+ (void)emitEventWithName:(NSString *)name andPayload:(NSDictionary *)payload;

@end

NS_ASSUME_NONNULL_END
