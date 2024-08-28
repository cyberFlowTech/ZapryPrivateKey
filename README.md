# ZapryPrivateKey

[![CI Status](https://img.shields.io/travis/285275534/ZapryPrivateKey.svg?style=flat)](https://travis-ci.org/285275534/ZapryPrivateKey)
[![Version](https://img.shields.io/cocoapods/v/ZapryPrivateKey.svg?style=flat)](https://cocoapods.org/pods/ZapryPrivateKey)
[![License](https://img.shields.io/cocoapods/l/ZapryPrivateKey.svg?style=flat)](https://cocoapods.org/pods/ZapryPrivateKey)
[![Platform](https://img.shields.io/cocoapods/p/ZapryPrivateKey.svg?style=flat)](https://cocoapods.org/pods/ZapryPrivateKey)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ZapryPrivateKey is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ZapryPrivateKey'
```

## Author

285275534, 285275534@qq.com

## License

ZapryPrivateKey is available under the MIT license. See the LICENSE file for more info.

shy todo 
这三种情况流程都是中断的(验证界面都是RN的)，导致会保留用户输入密码。解决方案可以修改为原生的，但是需要RN修改逻辑
1.创建钱包 (payType:9)
2.备份到iCloud (payType:12)
3.设置生物识别的时候验证密码 (payType:10)

4.密码会保存到userDefault上了，这种情况已经废弃掉了，已处理
5.2.8之前的privateKey是存储在UserDefault上的，使用kMultiUdKey来存储的，感觉这种方式可以废弃掉，目前还保留着,建议废弃掉
6.以下几种场景都是在rn界面上输入密码的
    查看助记词(payType:4)，
    解绑(payType:5)，
    创建钱包(payType:9)，
    设置生物识别的时候验证密码(payType:10)，
    加链(payType:11)，
    保存icloud(payType:12)
