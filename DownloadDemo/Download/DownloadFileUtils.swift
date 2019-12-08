//
//  DownloadFileUtils.swift
//  DownloadDemo
//
//  Created by 朴子hp on 2019/12/7.
//  Copyright © 2019 朴子hp. All rights reserved.
//

import UIKit

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

}
