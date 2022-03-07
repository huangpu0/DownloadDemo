//
//  DownloadManager.swift
//  DownloadDemo
//
//  Created by 朴子hp on 2019/12/4.
//  Copyright © 2019 朴子hp. All rights reserved.
//

import UIKit
import Foundation

class DownloadManager: NSObject {
    
    static let downloadManagerInstance = DownloadManager()
    
    var queue : OperationQueue
    
    private override init() {
        self.queue = {
            let operationQueue = OperationQueue()
        
            operationQueue.maxConcurrentOperationCount = 10
            operationQueue.isSuspended = false
            operationQueue.qualityOfService = .utility
            
            return operationQueue
        }()
        super.init()
        
        
        let defaultSessionConfig = URLSessionConfiguration.background(withIdentifier: "com.hp.download")
        defaultSessionConfig.timeoutIntervalForRequest  = 120; //给定时间内没有数据传输的超时时间
        defaultSessionConfig.timeoutIntervalForResource = 60; //给定时间内服务器查找资源超时时间
        defaultSession = URLSession.init(configuration: defaultSessionConfig,
                                          delegate: self,
                                          delegateQueue: queue)
    }
    
    func requestForURL(url:String) ->DownloadRequest?{
        for tmpRequest in self.taskList {
            if (tmpRequest.url == url) {
                return tmpRequest
            }
        }
        return nil
    }
    
    //MARK:- 控制下载队列数量
    func refreshDownloadTask(){
        downloadQueue.async {
            var startCount = 0
            for req in self.taskList {
                if (req.state == .downloading) {
                    startCount += 1
                }else if (req.state == .waiting) {
                    req.state = .downloading;
                    req.task?.resume()
                    startCount += 1
                    DispatchQueue.main.async(execute: {
                        req.delegate?.requestDownloadStart?(req)
                    })
                }
                if (startCount >= maxConcurrentTaskCount) {
                    break
                }
            }
        }
    }

    /**
     * 添加下载任务/恢复下载任务
     **/
    func updateTaskListRequst(_ request:DownloadRequest){
        downloadQueue.async {
            if self.taskList.contains(request){
                print("包含此下载请求..将其调整至任务队列最后")
                let tmpRequest = request
                
                if  let index = self.taskList.firstIndex(of: request){
                    self.taskList.remove(at: index)
                    self.taskList.append(tmpRequest)
                }
            }else {
                print("不包含此下载请求..将其加入任务队列中")
                self.taskList.append(request)
            }
            DispatchQueue.main.sync {
                self.refreshDownloadTask()
            }
        }
    }
    
    /**
     *移除下载任务 条件如下
     * 1)下载完成
     * 2)下载失败
     **/
    func removeTasklistAtRequest(_ request:DownloadRequest) {

        downloadQueue.async {
            if let index = self.taskList.firstIndex(of: request){
                self.taskList.remove(at: index)
            }
            DispatchQueue.main.async {
                self.refreshDownloadTask()
            }
        }
    }

    func startRequestTask(_ request:DownloadRequest){
        if(request.request == nil) {
            print("url错误")
            return
        }
        
        var task : URLSessionDownloadTask
        if (request.allowResume && request.resumeData != nil) {
            task = self.defaultSession.downloadTask(withResumeData: request.resumeData!)
        }else {
            task = self.defaultSession.downloadTask(with: request.request)
        }
        request.task = task
        request.state = .waiting
        self.updateTaskListRequst(request)
    }
    
    /// 暂停任务
    ///
    /// - Parameter request: request description
    func pauseRequest(_ request:DownloadRequest){
        request.state = .paused
        self.refreshDownloadTask()
        DispatchQueue.main.async {
            request.delegate?.requestDownloadPause?(request)
        }
    }
    
    
    /// 取消下载任务
    ///
    /// - Parameter request: request description
    func cancelRequest(_ request:DownloadRequest){
        request.state = .cancel
        request.deleteResumeDatat()
        self.removeTasklistAtRequest(request)
        DispatchQueue.main.async {
            request.delegate?.requestDownloadCancel?(request)
        }
    }
    
    
    let downloadQueue = DispatchQueue.init(label: "com.hp.download", qos: DispatchQoS.utility)
    var taskList :[DownloadRequest] = []
    var defaultSession : URLSession!
}


extension DownloadManager:URLSessionDelegate,URLSessionDownloadDelegate{
    
    //资源文件下载成功回掉此方法
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        for request in self.taskList {
            guard request.task?.currentRequest?.url?.absoluteString == downloadTask.currentRequest?.url?.absoluteString else{
                break
            }
            
            self.removeTasklistAtRequest(request)
            request.deleteResumeDatat() //移除断点续传缓存数据文件
            let savePath = request.savePath + "/" + request.saveFileName
            print("path==\(savePath)")
            do{
               try FileManager.default.moveItem(at: location.absoluteURL, to: URL.init(fileURLWithPath: savePath))
            }catch let error{
                print("移动文件= [\(request.savePath)] with error \(error)")
                DispatchQueue.main.async {
                    request.delegate?.requestDownloadFaild?(request, error: error)
                }
                return
            }
            DispatchQueue.main.async {
                request.delegate?.requestDownloadFinish?(request)
            }
            return
        }
    }

    //资源文件下载进度
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                              didWriteData bytesWritten: Int64,
                                      totalBytesWritten: Int64,
                              totalBytesExpectedToWrite: Int64) {
        
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        for request in taskList{
            guard request.task?.currentRequest?.url?.absoluteString == downloadTask.currentRequest?.url?.absoluteString else{
                break
            }
            if (request.progress > request.progress) {
                print("下载进度异常....")
            }
            if request.saveFileName.isEmpty{
                if let fileName = downloadTask.response?.suggestedFilename{
                    request.saveFileName = fileName
                }
            }
            request.progress = progress
            DispatchQueue.main.async {
                request.delegate?.requestDownloading?(request)
            }
        }
    }
    
    /**
    * fileOffset：继续下载时，文件的开始位置
    * expectedTotalBytes：剩余的数据总数
    */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64,
                                     expectedTotalBytes: Int64) {
        print("fileOffset: \(fileOffset)  totalBytes: \(expectedTotalBytes)")
    }
    
    //MARK: - NSURLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        var matchingRequest : DownloadRequest?
        for request in taskList{
            if(request.task == task) {
                matchingRequest = request
                break
            }
        }
        
        if matchingRequest != nil{
            self.removeTasklistAtRequest(matchingRequest!)
        }
        
        //下载完成
        guard error != nil else{
            DispatchQueue.main.async {
                matchingRequest?.delegate?.requestDownloadFinish?(matchingRequest!)
            }
            return
        }
        
        //请求取消
        let nsError:NSError = error! as NSError
        if nsError.code == NSURLErrorCancelled ||
           nsError.code == URLError.cancelled.rawValue{
            print("请求取消")
        }
       
        if(error != nil) {
            print("下载失败-\(error!)")
        //如果下载任务可以恢复，那么NSError的userInfo包含了NSURLSessionDownloadTaskResumeData键对应的数据，保存起来，继续下载要用到
            if let resumeData = (error! as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                print("已下载数据-\(resumeData)")
                let tmpPath = DownloadFileUtils.downloadTmpPath() + "/" + DownloadFileUtils.cachedFileNameForKey(key: (task.currentRequest?.url!.absoluteString)!)

                let isTrue = (resumeData as NSData).write(toFile: tmpPath, atomically: false)
                if (!isTrue) {
                    print("resumeData 缓存数据写入失败")
                }
                
            }

            DispatchQueue.main.async {
                matchingRequest?.delegate?.requestDownloadFaild?(matchingRequest!, error: error!)
            }
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("error==\(String(describing: error))")
    }
    
    //session完成事件
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
           //主线程调用
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                   appDelegate.backgroundSessionCompletionHandler = nil
                //调用此方法告诉操作系统，现在可以安全的重新suspend你的app
                completionHandler()
            }
        }
    }
    
}

