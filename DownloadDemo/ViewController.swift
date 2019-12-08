//
//  ViewController.swift
//  DownloadDemo
//
//  Created by 朴子hp on 2019/12/4.
//  Copyright © 2019 朴子hp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var load: Bool = false
    
    var request: DownloadRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard !DownloadFileUtils.isExistsSource("http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.2.4.dmg") else {
            print("已下载")
            return
        }
        
        request = DownloadRequest.initWithURL(url: "http://dldir1.qq.com/qqfile/QQforMac/QQ_V4.2.4.dmg")
        request!.delegate = self
        request!.allowResume = true
        request!.startDownload()
        
        request = DownloadRequest.initWithURL(url: "http://api.gfs100.cn/upload/20171218/201712181643211975.mp4")
        request!.delegate = self
        request!.allowResume = true
        request!.startDownload()
        
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if load == false {
           load = true
            request?.pauseDownload()
        }else{
           load = false
            request!.resumeDownload()
        }
        
    }
}


extension ViewController: DownloadDelegate {
    
    func requestDownloadStart(_ request:DownloadRequest){
        print("开始下载--\(request.progress)")
    }
    func requestDownloading(_ request:DownloadRequest){
        print("开始下载--\(request.progress)")
    }
    func requestDownloadPause(_ request:DownloadRequest){
        print("暂停下载--\(request.progress)")
        
    }
    func requestDownloadCancel(_ request:DownloadRequest){
        print("取消下载--\(request.progress)")
    }
    func requestDownloadFinish(_ request:DownloadRequest){
        print("完成下载--\(request.progress)")
    }
    
    func requestDownloadFaild(_ request:DownloadRequest,error:Error){
        print("下载失败--\(request.progress)")
    }
    
}
