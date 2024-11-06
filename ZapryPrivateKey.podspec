#
# Be sure to run `pod lib lint ZapryPrivateKey.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZapryPrivateKey'
  s.version          = '0.2.0'
  s.summary          = 'A short description of ZapryPrivateKey.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/285275534/ZapryPrivateKey'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '285275534' => '285275534@qq.com' }
  s.source           = {  :git => 'file:./ZapryPrivateKey', :tag => s.version.to_s }
  s.swift_version = '5.0'
  s.requires_arc = true
  s.ios.deployment_target = '13.0'
  s.source_files =  "ZapryPrivateKey/**/*.{swift,h,m}"
  s.resource = "ZapryPrivateKey/ZapryPrivateKey.bundle"

  s.dependency 'KeychainAccess', '~> 4.2.2'
  s.dependency 'HandyJSON', '~> 5.0.2'
  s.dependency 'CryptoSwift'
  s.dependency 'SnapKit', '~> 5.6.0'

end
