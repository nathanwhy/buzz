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
    
    func downloadFile(fromURL url: URL, toPath path: String) {
        self.filePath = path
        self.url = url
        
        if FileManager().fileExists(atPath: path) {
            if let fileInfo = try? FileManager().attributesOfItem(atPath: path), let length = fileInfo[.size] as? Int64 {
                progress.completedUnitCount = length
            }
        }
        var request = URLRequest(url: url)
        request.setValue("bytes=\(progress.completedUnitCount)-", forHTTPHeaderField: "Range")
        
        taskStartedAt = Date()
        let task = session.dataTask(with: request)
        task.resume()
        semaphore.wait()
    }
    
    func downloadFile(fromURL url: URL, toPath path: String, header: [String: String]?) {
        self.filePath = path
        self.url = url
        
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
        
        self.downloadFile(fromURL: self.url!, toPath: self.filePath!)
    }
    
    func show(progress: Int, barWidth: Int, speedInK: Int) {
        print("\r[", terminator: "")
        let pos = Int(Double(barWidth*progress)/100.0)
        for i in 0...barWidth {
            switch(i) {
            case _ where i < pos:
                print("=", terminator:"")
                break
            case pos:
                print("=", terminator:"")
                break
            default:
                print(" ", terminator:"")
                break
            }
        }
        if speedInK > 1024 {
            print("] \(progress)% \(String(format: "%.2f", Double(speedInK) / 1024.0))MB/s", terminator:"")
        } else {
            print("] \(progress)% \(speedInK)KB/s", terminator:"")
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
        
        if progress.completedUnitCount == progress.totalUnitCount && 0 != progress.totalUnitCount {
            print("already exists, nothing to do!")
            completionHandler(.cancel)
            return
        }
        
        if progress.completedUnitCount > progress.totalUnitCount {
            print("file size error!")
            try! FileManager.default.removeItem(at: URL.init(fileURLWithPath: self.filePath!))
            completionHandler(.cancel)
            progress.completedUnitCount = 0
            resumeDownload();
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
        _ = data.withUnsafeBytes { outputStream?.write($0, maxLength: data.count) }
        
        let _progress = Int(self.progress.fractionCompleted * 100.0)
        var kbs = 0
        
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
        
        if cost <= 0.8 && _progress < 100 {
            return
        }
        if dataCount > lastData {
            kbs = Int(Double(dataCount - lastData) / 1024 / cost)
        }
        
        progress.setUserInfoObject(dataCount, forKey: .fileCompletedCountKey)
        progress.setUserInfoObject(time, forKey: .estimatedTimeRemainingKey)
        
        show(progress: _progress, barWidth: 50, speedInK: kbs)
    }
    
    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        outputStream?.close()
        outputStream = nil
        
        guard let error = error else {
            defer {
                semaphore.signal()
            }
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
        
        print("")
        print("Ooops! Something went wrong: \(error.localizedDescription)")
    }
}
