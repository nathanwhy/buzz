//
//  DownloadSessionManager.swift
//  CommandLineToolCore
//
//  Created by why on 2018/3/21.
//

import Foundation
import Cocoa

extension Notification.Name {
    static let flagsChanged = Notification.Name("FlagsChanged")
}

struct Network {
    static var reachability: Reachability?
    enum Status: String, CustomStringConvertible {
        case unreachable, wifi, wwan
        var description: String { return rawValue }
    }
    enum Error: Swift.Error {
        case failedToSetCallout
        case failedToSetDispatchQueue
        case failedToCreateWith(String)
        case failedToInitializeWith(sockaddr_in)
    }
}

class DownloadSessionManager : NSObject, URLSessionDataDelegate {
    static let sharedInstance = DownloadSessionManager()
    var filePath : String?
    var url: URL?
    var progress: Progress = Progress()
    var header: [String: String]?
    
    let semaphore = DispatchSemaphore.init(value: 0)
    var session : URLSession!
    var outputStream: OutputStream?

    override init() {
        super.init()
        self.resetSession()
    }

    func resetSession() {
        self.session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }

    func downloadFile(fromURL url: URL, toPath path: String, header: [String: String]?) {
        self.filePath = path
        self.url = url
        self.header = header
        
        if FileManager().fileExists(atPath: path) {
            if let fileInfo = try? FileManager().attributesOfItem(atPath: path), let length = fileInfo[.size] as? Int64 {
                progress.completedUnitCount = length
            }
        }
        
        var request = URLRequest(url: url)
        
        request.setValue("bytes=\(progress.completedUnitCount)-", forHTTPHeaderField: "Range")
        
        if let header = header, header.count > 0 {
            header.forEach({ (key, value) in
                request.setValue(value, forHTTPHeaderField: key)
            })
        }
        
        taskStartedAt = Date()
        let task = session.dataTask(with: request)
        task.resume()
        semaphore.wait()
    }

    func resumeDownload() {
        self.resetSession()
        self.downloadFile(fromURL: self.url!, toPath: self.filePath!, header: self.header)
    }

    func showDownloadInfo() {
        let barWidth = 50
        var bytesPerSecond = 0.0
        let downloadProgress = Int(self.progress.fractionCompleted * 100.0)
        
        let dataCount = progress.completedUnitCount
        var lastData: Int64 = 0
        if let temp = progress.userInfo[.fileCompletedCountKey] as? Int64 {
            lastData = temp
        }
        
        let time = Date().timeIntervalSince1970
        var lastTime: Double = 0
        if let temp = progress.userInfo[.estimatedTimeRemainingKey] as? Double {
            lastTime = temp
        }
        
        let cost = time - lastTime
        
        if cost <= 0.8 && downloadProgress < 100 {
            return
        }
        if dataCount > lastData {
            bytesPerSecond = Double(dataCount - lastData) / cost
        }
        
        progress.setUserInfoObject(dataCount, forKey: .fileCompletedCountKey)
        progress.setUserInfoObject(time, forKey: .estimatedTimeRemainingKey)
        
        print("\r[", terminator: "")
        let pos = Int(Double(barWidth * downloadProgress) / 100.0)
        for i in 0...barWidth {
            switch(i) {
            case _ where i < pos:
                print("=", terminator:"")
                break
            case pos:
                print(">", terminator:"")
                break
            default:
                print(" ", terminator:"")
                break
            }
        }
        
        print("] \(downloadProgress)% \(bytesPerSecond.convertSpeedToString())", terminator:"")
        
        if downloadProgress >= 100, let startrdAt = taskStartedAt {
            let diff = Date().timeIntervalSince(startrdAt)
            print(" in \(diff.convertTimeToString())", terminator:"")
        }
        fflush(__stdoutp)
    }
    
    //MARK : URLSessionDataDelegate stuff
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse else { return  }
        
        if let bytesStr = response.allHeaderFields["Content-Length"] as? String, let totalBytes = Int64(bytesStr) {
            progress.totalUnitCount = totalBytes
        }
        
        if let contentRangeStr = response.allHeaderFields["content-range"] as? NSString {
            if contentRangeStr.length > 0 {
                progress.totalUnitCount = Int64(contentRangeStr.components(separatedBy: "/").last!)!
            }
        }
        
        if let contentRangeStr = response.allHeaderFields["Content-Range"] as? NSString {
            if contentRangeStr.length > 0 {
                progress.totalUnitCount = Int64(contentRangeStr.components(separatedBy: "/").last!)!
            }
        }
        
        if progress.completedUnitCount >= progress.totalUnitCount && 0 != progress.totalUnitCount {
            print("already exists, nothing to do!")
            completionHandler(.cancel)
            return
        }
        
        if response.statusCode >= 300 || response.statusCode < 200 {
            let statusCodeStr = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            print("ERROR \(response.statusCode): " + statusCodeStr)
            completionHandler(.cancel)
            return
        }
        
        outputStream = OutputStream(toFileAtPath: self.filePath!, append: true)
        outputStream?.open()
        completionHandler(.allow)
        print("start to download ..")
    }

    var taskStartedAt : Date?

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let dataLength = Int64((data as NSData).length)
        progress.completedUnitCount += dataLength
        _ = data.withUnsafeBytes { (ptr) -> UInt8 in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return 0
            }
            outputStream?.write(bytes, maxLength: data.count)
            return bytes.pointee
        }
        showDownloadInfo()
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        outputStream?.close()
        outputStream = nil
        
        guard let error = error else {
            defer {
                semaphore.signal()
            }
            print("download complete")
            return
        }
        
        defer {
            defer {
                semaphore.signal()
            }
            
            if !Reachability.isConnectedToNetwork() {
                print("Waiting for connection to be restored")
                repeat {
                    sleep(1)
                } while !Reachability.isConnectedToNetwork()
            }
        }
        
        print("Ooops! Something went wrong: \(error.localizedDescription)")
    }
}
