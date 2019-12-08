//
//  DownloadDelegate.swift
//  DownloadDemo
//
//  Created by 朴子hp on 2019/12/7.
//  Copyright © 2019 朴子hp. All rights reserved.
//

import Foundation

@objc protocol DownloadDelegate : class {
    
    @objc optional func requestDownloadStart(_ request: DownloadRequest)
    @objc optional func requestDownloading(_ request: DownloadRequest)
    @objc optional func requestDownloadPause(_ request: DownloadRequest)
    @objc optional func requestDownloadCancel(_ request: DownloadRequest)
    @objc optional func requestDownloadFinish(_ request: DownloadRequest)
    @objc optional func requestDownloadFaild(_ request: DownloadRequest,error:Error)

}
