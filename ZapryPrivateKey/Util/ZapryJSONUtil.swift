//
//  ZapryJSONUtil.swift
//  MIMO
//
//  Created by zhang shuai on 2023/4/19.
//

import UIKit
import HandyJSON

// 使用泛型

@objcMembers
public class ZapryJSONUtil: NSObject {
    /**
     *  Json转对象
     */
    public static func jsonToModel<T: HandyJSON>(_ jsonStr:String,_ modelType:HandyJSON.Type) -> T? {
        if jsonStr == "" || jsonStr.count == 0 {
            #if DEBUG
                print("jsonoModel:字符串为空")
            #endif
            return T()
        }
        return modelType.deserialize(from: jsonStr)  as? T
        
    }
    
    /**
     *  Json转数组对象
     */
    public static func jsonArrayToModel<T: HandyJSON>(_ jsonArrayStr:String, _ modelType:HandyJSON.Type) ->[T] {
        if jsonArrayStr == "" || jsonArrayStr.count == 0 {
            #if DEBUG
                print("jsonToModelArray:字符串为空")
            #endif
            return []
        }
        var modelArray:[T] = []
        let data = jsonArrayStr.data(using: String.Encoding.utf8)
        let peoplesArray = try! JSONSerialization.jsonObject(with:data!, options: JSONSerialization.ReadingOptions()) as? [AnyObject]
        for people in peoplesArray! {
            modelArray.append(dictionaryToModel(people as! [String : Any], modelType as! T.Type)!)
        }
        return modelArray
        
    }
    
    /**
     *  字典转对象
     */
    public static func dictionaryToModel<T: HandyJSON>(_ dictionStr:[String:Any], _ modelType: T.Type) -> T? {
        if dictionStr.count == 0 {
            #if DEBUG
                print("dictionaryToModel:字符串为空")
            #endif
            return modelType.init()
        }
        return modelType.deserialize(from: dictionStr)
    }
    
    /**
     *  对象转JSON
     */
    public static func modelToJson<T: HandyJSON>(_ model:T?) -> String {
        if model == nil {
            #if DEBUG
                print("modelToJson:model为空")
            #endif
             return ""
        }
        return (model?.toJSONString())!
    }
    
    /**
     *  对象转字典
     */
    public static func modelToDictionary<T: HandyJSON>(_ model:T?) -> [String:Any] {
        if model == nil {
            #if DEBUG
                print("modelToJson:model为空")
            #endif
            return [:]
        }
        return (model?.toJSON())!
    }
    
    // 数组转换为jsonstring
    public  class func getJSONStringFromArray(array: [Any]) -> String? {
        if (!JSONSerialization.isValidJSONObject(array)) {
            print("无法解析出JSONString")
            return nil
        }
        if let data = try? JSONSerialization.data(withJSONObject: array, options: []), let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue) as String? {
            return JSONString
        }
        return nil
    }
    
    // MARK: 字符串转字典
    public class func stringToDic(_ str: String?) -> [String: Any]? {
       
       guard let data = str?.data(using: String.Encoding.utf8) else {
           return nil
       }
       if let dict = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : Any] {
           return dict
       }
       return nil
    }
    
    public class func dicToJsonString(dic: [String: Any]) -> String? {

        if (!JSONSerialization.isValidJSONObject(dic)) {
            print("无法解析出JSONString")
            return nil
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: dic, options: []) {
            let jsonString = String(data: data, encoding: .utf8)
            return jsonString
        }
        return nil
    }

}
