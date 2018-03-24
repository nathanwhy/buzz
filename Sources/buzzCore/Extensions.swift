//
//  Extensions.swift
//  CommandLineToolCore
//
//  Created by why on 2018/3/21.
//

import Foundation

extension String {
    
    public func queryDictionary() -> [String: String]? {
        
        var queryDic: [String: String] = [:]
        let pairs = self.components(separatedBy: ";")
        
        pairs.forEach { str in
            let pair = str.components(separatedBy: ":")
            if pair.count == 2 {
                queryDic[pair[0]] = pair[1]
            }
        }
        return queryDic
    }
    
    public func isValidURLString() -> Bool {

        let predicateStr = "^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$"
        let predicate =  NSPredicate(format: "SELF MATCHES %@" ,predicateStr)
        return predicate.evaluate(with: self)
    }
}


extension Double {
    
    public func convertTimeToString() -> String {
        if self <= 0 { return "" }
        if self < 60 {
            return "\(String(format: "%.1f", self))s"
        }
        var timeString = ""
        if self >= 86400 {
            timeString += "\(Int(self) / 86400)d "
        }
        if self >= 3600 {
            timeString += "\(Int(self) % 86400 / 3600)h "
        }
        if self >= 60 {
            timeString += "\(Int(self) % 3600 / 60)m "
        }
        timeString += "\(Int(self) % 60)s"
        return timeString
    }
    
    public func convertSpeedToString() -> String {
        if self <= 0 { return "" }
        if self >= pow(1024, 3) {
            return "\(String(format: "%.2f", self / pow(1024, 3)))GB/s"
        } else if self >= pow(1024, 2) {
            return "\(String(format: "%.2f", self / pow(1024, 2)))MB/s"
        } else if self >= 1024 {
            return "\(String(format: "%.0f", self / 1024))KB/s"
        } else {
            return "\(Int(self))B/s"
        }
    }
    
    public func convertBytesToString() -> String {
        switch self {
        case _ where self >= pow(1024, 3):
            return "\(String(format: "%.2f", self / pow(1024, 3)))GB"
        case pow(1024, 2)..<pow(1024, 3):
            return "\(String(format: "%.2f", self / pow(1024, 2)))MB"
        case 1024..<pow(1024, 2):
            return "\(String(format: "%.0f", self / 1024))KB"
        default:
            return "\(Int(self))B"
        }
    }
}
