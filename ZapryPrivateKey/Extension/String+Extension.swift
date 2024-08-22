//
//  StringExtension.swift
//  SCPApp
//
//  Created by 37 on 2022/10/14.
//

import Foundation
import CryptoKit

fileprivate let hexPre = "0x"

public extension String {
    
   var md5: String {
        let digest = Insecure.MD5.hash(data: data(using: .utf8) ?? Data())

        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
    
    // Base64 encoding a string
   func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }

    // Base64 decoding a string
     func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    
    /// 根据正则表达式校验字符串
    /// - Parameter regex: 正则表达式
    /// - Returns: 是否匹配
    func validate(_ regex: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES%@", regex)
        return predicate.evaluate(with: self)
    }
    
    var hexInt: Int {
        return Int(self, radix: 16) ?? 0
    }
    
    func substring(start: Int, end: Int) -> String {
        let firstIndex = index(startIndex, offsetBy: start)
        let lastIndex = index(startIndex, offsetBy: end)
        return String(self[firstIndex..<lastIndex])
    }
    
    func substring(from: Int) -> String {
        let firstIndex = index(startIndex, offsetBy: from)
        let lastIndex = index(startIndex, offsetBy: self.count)
        return String(self[firstIndex..<lastIndex])
    }
    
    func stripHexPre() -> String {
        var hex = self
        if hex.hasPrefix(hexPre) {
            hex = String(hex.dropFirst(hexPre.count))
        }
        return hex
    }
    
    func isValidUrl() ->Bool {
        if let url = URL(string: self), url.isFileURL ||  (!(url.scheme?.isEmpty ?? true) && (url.scheme == "https" || url.scheme == "http")) {
            return true
        } else {
            return false
        }
    }
    
    //去掉url 前面的无效字符
    func getValidUrl() -> String {
        var targetStr:String = self
        let httpStr = "http://"
        let httpsStr = "https://"
        if let range = self.range(of:httpStr) {
            let startIndex = self.distance(from: self.startIndex, to:range.lowerBound)
            targetStr = self.substring(from:startIndex)
        }else if let range = self.range(of: httpsStr) {
            let startIndex = self.distance(from: self.startIndex, to:range.lowerBound)
            targetStr = self.substring(from:startIndex)
        }
        return targetStr
    }
    
    func hexToStringWithMimo() -> String {
        let str = self.stripHexPre()
        let hexArray = Array<UInt8>.init(hex:str)
        let data = Data(bytes: hexArray)
        let decodeStr = String.init(data: data, encoding: .utf8) ?? self
        return decodeStr
    }
    
    func isNumber() -> Bool {
        let scan: Scanner = Scanner(string: self)
        var val:Int = 0
        return scan.scanInt(&val) && scan.isAtEnd
    }
}
