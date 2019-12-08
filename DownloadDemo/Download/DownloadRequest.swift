//
//  DownloadRequest.swift
//  DownloadDemo
//
//  Created by 朴子hp on 2019/12/7.
//  Copyright © 2019 朴子hp. All rights reserved.
//

import Foundation

class DownloadRequest: NSObject{
    
    private(set) var request : URLRequest!//请求对象
    
    var state : DownloadEvent = .none            //请求状态
    var tempPath : String {                     //临时文件目录 暂未使用
        return DownloadFileUtils.downloadTmpPath()
    }
    
    var savePath : String{                      //保存文件路径 默认 /Downloads/FileDownload/
        return DownloadFileUtils.downloadPath()
    }
    
    var saveFileName : String = ""          //保存文件名 默认服务器返回的文件名
    var allowResume:Bool = false           //是否支持断点续传 默认NO
    var task: URLSessionDownloadTask?      //下载任务对象
    weak var delegate: DownloadDelegate?   //代理
    var progress : Float = 0               //下载进度 范围0.0~1.0
    var url : String = ""                  //下载文件的远程地址URL
    private(set) var resumeData:Data?      //断点续传的Data(包含URL信息)
    
    weak var manager = DownloadManager.downloadManagerInstance
    
    convenience init(url:String) {
        self.init()
        self.url = url
        self.doInit()
    }
    /**
     * 实例化请求对象 已经存在则返回 不存在则创建一个并返回
     **/
    class func initWithURL(url:String) -> DownloadRequest{
        var request = DownloadManager.downloadManagerInstance.requestForURL(url: url)
        
        if (request == nil) {
            request = DownloadRequest.init(url: url)
        }
        return request!
    }
 
    func requestUrl()->URL{
        return URL.init(string: url)!
    }
    
    
    func doInit(){
        self.request = URLRequest.init(url: self.requestUrl())
        self.request.cachePolicy = .reloadRevalidatingCacheData
        self.allowResume = true
        self.resumeData = self.readResumeData()
    }
        
    deinit {
        print("dealloc")
    }
    
}

extension DownloadRequest {
    
    /**
     * 读取本地保存的文件下载断点位置信息数据
     **/
    func readResumeData()->Data?{
        let resumeDataPath = DownloadFileUtils.downloadTmpPath() + "/" + DownloadFileUtils.cachedFileNameForKey(key: url)
        if let resume_Data = NSData.init(contentsOfFile: resumeDataPath){
            return resume_Data as Data
        }
        return nil
    }
    /**
     *开始下载任务 适用于首次添加下载任务
     **/
    func startDownload(){
        self.manager?.startRequestTask(self)
    }
    /**
     * 暂停下载任务
     * 注意初始化时allowResume 属性为YES 否则无效
     **/
    func pauseDownload(){
    if (!self.allowResume) {
        return
    }
        
    if (self.state == .paused) {
        print("任务暂停失败 因为此任务本身处于暂停状态")
        return
    }
        
        self.task?.cancel(byProducingResumeData: { [weak self](resumeData) in
            // resumeData : 包含了继续下载的开始位置\下载的url
            self?.resumeData = resumeData
            self?.task = nil
            self?.manager?.pauseRequest(self!)
            self?.resumeDatatWriteToFile()
        })
    }
    
    //断点缓存数据写入文件
    func resumeDatatWriteToFile(){
        if (self.resumeData == nil) {
            print("resumeData 为空")
            return
        }
        let tmpPath = DownloadFileUtils.downloadTmpPath() + "/" + DownloadFileUtils.cachedFileNameForKey(key: url)
        
       let isTrue = (self.resumeData! as NSData).write(toFile: tmpPath, atomically: false)
        
        if (!isTrue) {
            print("resumeData 缓存数据写入失败")
        }
    }
    
    //移除断点缓存数据
    func deleteResumeDatat() -> Void {
        
    let tmpPath = DownloadFileUtils.downloadTmpPath() + "/" + DownloadFileUtils.cachedFileNameForKey(key: url)
        if FileManager.default.fileExists(atPath: tmpPath){
           try? FileManager.default.removeItem(atPath: tmpPath)
        }
    }
    
    /**
     * 恢复下载任务
     * 注意初始化时allowResume 属性为YES 否则无效
     **/
    func resumeDownload(){
        guard self.allowResume else {
            return
        }
        
        guard self.state == .paused else{
            print("任务恢复失败 因为此任务本身处于非暂停状态")
            return
        }
        self.manager?.startRequestTask(self)
        self.resumeData = nil
    }
    
    /**
     * 取消下载任务
     **/
    func cancelDownload() -> Void {
        if (self.state == .downloading) {
            self.task?.cancel()
        }
        self.manager?.cancelRequest(self)
    }
    
}
