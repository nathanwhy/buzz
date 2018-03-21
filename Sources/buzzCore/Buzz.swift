//
//  Buzz.swift
//  CommandLineToolCore
//
//  Created by why on 2018/3/21.
//

import Foundation
import Cocoa
import Files
import CommandLineKit

let appVersion = "0.1.0"

public final class Buzz {
    private let arguments: [String]
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    public func run() throws {
        
        let cli = CommandLineKit.CommandLine(arguments: self.arguments)
        
        
        let headerOption = StringOption(longFlag: "header", helpMessage: "insert string among the headers")
        cli.addOption(headerOption)
        
        let versionOption = BoolOption(shortFlag: "v", longFlag: "version", helpMessage: "Print version.")
        cli.addOption(versionOption)
        
        let helpOption = BoolOption(shortFlag: "h", longFlag: "help", helpMessage: "Print this help message.")
        cli.addOption(helpOption)
        
        do {
            try cli.parse()
        } catch {
            cli.printUsage(error)
            exit(EX_USAGE)
        }
        
        if helpOption.value {
            cli.printUsage()
            exit(EX_OK)
        }
        
        if versionOption.value {
            print(appVersion)
            exit(EX_OK)
        }
        
        guard let urlString = arguments.last else {
            print("Missing URL!")
            return
        }
        guard urlString.isValidURLString() else {
            print("\"\(urlString)\" is not valid URL!")
            return
        }
        guard let url = URL(string: urlString) else {
            return
        }
        
        let fileName = URL(fileURLWithPath: urlString).lastPathComponent
        
        print("Getting \(fileName) (\(urlString)):")
        
        var header: [String: String]?
        if let headerValue = headerOption.value {
            header = headerValue.queryDictionary()
        }
        DownloadSessionManager.sharedInstance.downloadFile(fromURL: url, toPath: fileName, header: header)
    }
}

public extension Buzz {
    enum Error: Swift.Error {
        case missingURL
        case missingFileName
    }
}
