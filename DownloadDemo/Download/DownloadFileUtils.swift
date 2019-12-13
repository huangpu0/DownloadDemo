//
//  DownloadFileUtils.swift
//  DownloadDemo
//
//  Created by 朴子hp on 2019/12/4.
//  Copyright © 2019 朴子hp. All rights reserved.
//

import UIKit
import CommonCrypto

class DownloadFileUtils: NSObject {
    
    //默认下载临时路径
    class func downloadTmpPath()->String{
        let documentPaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
        let docsDir = documentPaths.first
        let tmpPath = docsDir! + "/" + "TmpDownload"
        DownloadFileUtils.checkFilePath(path: tmpPath)
        return tmpPath
    }
       
    //默认下载路径
    class func downloadPath() -> String{
        let documentPaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
        let docsDir = documentPaths.first
        let tmpPath = docsDir! + "/" + "FileDownload"
        DownloadFileUtils.checkFilePath(path: tmpPath)
        return tmpPath
    }
    
    //获取资源文件名
    class func cachedFileNameForKey(key:String) -> String{
        return (URL.init(string: key)!.lastPathComponent as NSString).deletingPathExtension
    }
    
    //判断当前资源是否已下载
    class func isExistsSource(_ name: String) -> Bool {
        let path = downloadPath() + "/" + URL.init(string: name)!.lastPathComponent
        print("文件路径-\(path)")
        return FileManager.default.fileExists(atPath: path)
    }
    
    //获取本地已下载的数据
    class func readResumeData(_ url: String) -> Data?{
        let resumeDataPath = DownloadFileUtils.downloadTmpPath() + "/" + DownloadFileUtils.cachedFileNameForKey(key: url)
        if let resume_Data = NSData.init(contentsOfFile: resumeDataPath){
            return resume_Data as Data
        }
        return nil
    }
    
    //检查是否已创建该文件
    class func checkFilePath(path:String){
           
        guard !FileManager.default.fileExists(atPath: path) else {
            return
        }
        
        do{
           try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }catch {
            print("文件错误-\(error)")
        }
    }

    //移除文件
    static func removeFile(_ url: String) -> Void {
        let path = downloadPath() + "/" + URL.init(string: url)!.lastPathComponent
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch  {
            print("删除文件错误-\(error)")
        }
    }
    
}

//MARK: - 校证文件的正确性 md5（需服务器返回对应数据、下载完成后进行比对、校正）
extension DownloadFileUtils {
    
   class func md5File(_ url: URL) -> String? {
        
        let bufferSize = 1024 * 1024
    
        do {
            //打开文件
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }
            
            //初始化内容
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)
            
            //读取文件信息
            while case let data = file.readData(ofLength: bufferSize), data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_MD5_Update(&context, $0, CC_LONG(data.count))
                }
            }
            
            //计算Md5摘要
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_MD5_Final($0, &context)
            }
            return digest.map { String(format: "%02hhx", $0) }.joined()
            
        } catch {
            print("不能打开文件:-", error.localizedDescription)
            return nil
        }
    }
    
}

