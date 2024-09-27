//
//  RNOCBridge.m
//  MIMO
//
//  Created by gaofeng on 2023/10/30.
//

#import "MimoReactNativeModule.h"
#import "ZapryPrivateKey_Example-Swift.h"

static MimoReactNativeModule *instance = nil;

@implementation MimoReactNativeModule

// 导出一个模块，括号内是可选的，若不填，默认为类名
RCT_EXPORT_MODULE();

+ (instancetype)shared {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
  });
  return instance;
}

// 导出一个普通的异步方法

// 导出一个支持Promise的异步方法
RCT_EXPORT_METHOD(action:(NSString *)action
                  params:(NSString *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [RNManager rnCallWithAction:action
                         params:params
                       resolver:resolve
                         reject:reject];
}

// 导出一个同步方法

// 导出常量供rn使用

#pragma mark - 事件
// 事件，没有回调

- (NSArray<NSString *> *)supportedEvents {
    //这里返回的将是你要发送的消息名的数组。
    return @[NATIVE_TO_RN_Notify_Wallet_Jostle,
             NATIVE_Call_RN_Wallet_Recharge,
             NATIVE_Notify_Wallet_Exit,
             NATIVE_Notify_Pay_Notification
    ];
}

- (void)startObserving
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jostleEventInternal:)
                                                 name:NATIVE_TO_RN_Notify_Wallet_Jostle
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rechargeEventInternal:)
                                                 name:NATIVE_Call_RN_Wallet_Recharge
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(walletExitEventInternal:)
                                                 name:NATIVE_Notify_Wallet_Exit
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(payNotificationEventInternal:)
                                                 name:NATIVE_Notify_Pay_Notification
                                               object:nil];
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)jostleEventInternal:(NSNotification *)notification
{
    [self sendEventWithName:NATIVE_TO_RN_Notify_Wallet_Jostle
                       body:notification.userInfo];
}

- (void)rechargeEventInternal:(NSNotification *)notification {
    [self sendEventWithName:NATIVE_Call_RN_Wallet_Recharge
                       body:notification.userInfo];
}

- (void)walletExitEventInternal:(NSNotification *)notification {
    [self sendEventWithName:NATIVE_Notify_Wallet_Exit
                       body:notification.userInfo];
}

- (void)payNotificationEventInternal:(NSNotification *)notification {
    [self sendEventWithName:NATIVE_Notify_Pay_Notification
                       body:notification.userInfo];
}

+ (void)emitEventWithName:(NSString *)name andPayload:(NSDictionary *)payload
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                        object:self
                                                      userInfo:payload];
}

@end
