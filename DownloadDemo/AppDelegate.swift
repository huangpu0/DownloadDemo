//
//  AppDelegate.swift
//  DownloadDemo
//
//  Created by 朴子hp on 2019/12/4.
//  Copyright © 2019 朴子hp. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


    //用于保存后台下载的completionHandler
    var backgroundSessionCompletionHandler: (() -> Void)?
    
    //后台下载完毕后会调用（我们将其交由下载工具类做后续处理）
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
         
        //用于保存后台下载的completionHandler
        backgroundSessionCompletionHandler = completionHandler
         
        //创建download session
        let configuration    = URLSessionConfiguration.background(withIdentifier: identifier)
        let downloadssession = URLSession(configuration: configuration,
                                          delegate: DownloadManager.downloadManagerInstance.defaultSession as? URLSessionDelegate,
                                          delegateQueue: nil)
         
        //指定download session
        DownloadManager.downloadManagerInstance.defaultSession = downloadssession
    }
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

