//
//  DownloadState.swift
//  DownloadDemo
//
//  Created by 朴子hp on 2019/12/4.
//  Copyright © 2019 朴子hp. All rights reserved.
//

import Foundation

enum DownloadEvent {
    
    case none //默认
    
    case downloading //下载...
    
    case waiting //等待
    
    case paused //暂停
        
    case cancel //取消
    
}

let maxConcurrentTaskCount = 3 //下载队列并发数



