//
//  WalletSdkRNModule.m
//  MIMO
//
//  Created by admin  on 2024/2/20.
//

#import "WalletSdkRNModule.h"
#import "ZapryPrivateKey_Example-Swift.h"



static WalletSdkRNModule *instance = nil;

@implementation WalletSdkRNModule

// 导出一个模块，括号内是可选的，若不填，默认为类名
RCT_EXPORT_MODULE();

+ (instancetype)shared {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
  });
  return instance;
}

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

#pragma mark - 事件
// 事件，没有回调

- (NSArray<NSString *> *)supportedEvents {
    //这里返回的将是你要发送的消息名的数组。
    return @[NATIVE_Notify_Send_Transaction,NATIVE_Notify_Get_Balance,NATIVE_Notify_Sign];
}

- (void)startObserving
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(walletSdkEventInternal:)
                                                 name:NATIVE_Notify_Send_Transaction
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getBalanceEventWithWalletSdk:)
                                                 name:NATIVE_Notify_Get_Balance
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signEventWithWalletSdk:)
                                                 name:NATIVE_Notify_Sign
                                               object:nil];
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)walletSdkEventInternal:(NSNotification *)notification {
    [self sendEventWithName:NATIVE_Notify_Send_Transaction
                       body:notification.userInfo];
}

- (void)getBalanceEventWithWalletSdk:(NSNotification *)notification {
    [self sendEventWithName:NATIVE_Notify_Get_Balance body:notification.userInfo];
}

- (void)signEventWithWalletSdk:(NSNotification *)notification {
    [self sendEventWithName:NATIVE_Notify_Sign body:notification.userInfo];
}

+ (void)emitEventWithName:(NSString *)name andPayload:(NSDictionary *)payload
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                        object:self
                                                      userInfo:payload];
}

@end
