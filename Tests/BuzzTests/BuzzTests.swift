import Foundation
import XCTest
import Files
import buzzCore

let bigFileUrl = "https://officecdn-microsoft-com.akamaized.net/pr/C1297A47-86C4-4C1F-97FA-950631F94777/OfficeMac/Microsoft_Office_2016_16.10.18021001_Installer.pkg"
let videoUrl = "http://mycdn.seeyouyima.com/news/vod/1b389b8678066924d8f493866d4e84f5.mp4"
let imgUrl = "http://fdfs.xmcdn.com/group21/M0B/AF/1B/wKgJLVivxqOiF8OsAAFUzt0qmg4260_mobile_large.jpg"
let failedUrl = "https://httpbin.org/status/404"

class BuzzTests: XCTestCase {
    func testCreatingFile() throws {
        
        let fileSystem = FileSystem()
        let tempFolder = fileSystem.temporaryFolder
        let testFolder = try tempFolder.createSubfolderIfNeeded(
            withName: "CommandLineToolTests"
        )
        try testFolder.empty()
        let fileManager = FileManager.default
        fileManager.changeCurrentDirectoryPath(testFolder.path)
        
        let arguments = [testFolder.path, imgUrl]
        let tool = Buzz(arguments: arguments)
        try tool.run()
        
        XCTAssertNotNil(try? testFolder.file(named: "wKgJLVivxqOiF8OsAAFUzt0qmg4260_mobile_large.jpg"))
    }
    
    func testHeaderStringValue() throws {
        
        let cookie = "Cookie: ADCDownloadAuth=1bkj5Id1"
        let header = cookie.queryDictionary()!
        
        XCTAssertTrue(header.count == 1)
        XCTAssertTrue(header["Cookie"] == " ADCDownloadAuth=1bkj5Id1")
        
        let mutiStr = "a:b; b:d"
        XCTAssertTrue(mutiStr.queryDictionary()!.count == 2)
    }
    
    func testValiURLString() throws {
        
        XCTAssertFalse("Hehe".isValidURLString())
        XCTAssertTrue("http://google.com".isValidURLString())
        XCTAssertTrue("https://google.com".isValidURLString())
    }
    
    
    func testConvertTimeToString() throws {
        
        let testArray = [-1.0, 6, 66, 6666, 86921]
        let expections = ["", "6s", "1m 6s", "1h 51m 6s", "1d 0h 8m 41s"]
        
        for i in 0..<testArray.count {
            XCTAssertTrue(expections[i] == testArray[i].convertTimeToString())
        }
    }
    
    func testConvertSpeedToString() throws {
        
        let testArray = [-1, 1023.0, 1024.0, 1025.0, 10241023.0, 1073741824.1]
        let expections = ["", "1023B/s", "1KB/s", "1KB/s", "9.77MB/s", "1.00GB/s"]
        
        for i in 0..<testArray.count {
            XCTAssertTrue(expections[i] == testArray[i].convertSpeedToString())
        }
    }
    
    func testConvertBytesToString() throws {
        
        let testArray = [1023.0, 1024.0, 1025.0, 10241023.0, 1073741824.1]
        let expections = ["1023B", "1KB", "1KB", "9.77MB", "1.00GB"]
        
        for i in 0..<testArray.count {
            XCTAssertTrue(expections[i] == testArray[i].convertBytesToString())
        }
    }
    
    func testNetworkEnable() throws {
        XCTAssertTrue(Reachability.isConnectedToNetwork())
    }
}
