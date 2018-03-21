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
        // to do ...
        let predicateStr = "^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$"
        let predicate =  NSPredicate(format: "SELF MATCHES %@" ,predicateStr)
        return predicate.evaluate(with: self)
//        return self.contains("http://") || self.contains("https://")
    }
}
