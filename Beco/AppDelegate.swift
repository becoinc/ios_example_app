//
//  AppDelegate.swift
//  Beco
//
//  Copyright © 2017 Beco. All rights reserved.
//

import UIKit

import XCGLogger


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    
    var window   : UIWindow?
    var mControl : ViewController!
    
    static let scCacheDirectory: URL =
        {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return urls[ urls.endIndex - 1 ]
        }()
    static let scMaxLogFiles = 10
    
    func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        mControl = ViewController()

        application.statusBarStyle = UIStatusBarStyle.lightContent
     
        // Setup debug logging.
        setupLogger(log: gLog, cacheDir: AppDelegate.scCacheDirectory )
            
        if let locLaunch = launchOptions?[ UIApplicationLaunchOptionsKey.location ] as? NSNumber {
            gLog.debug("Launched due to Location: \(locLaunch.boolValue)")
            doBackgroundFetchLaunch( nil )
        }
        else if application.applicationState == .background {
            // We launched due to a background fetch.
            gLog.debug("Launched on Background fetch.")
            doBackgroundFetchLaunch( nil )
        }
        else {
            gLog.info("")   // Put at least one entry in log to start things off.
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions
        // (such as an incoming phone call or SMS message) or when the user
        // quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and
        // throttle down OpenGL ES frame rates.
        // Games should use this method to pause the game.
        gLog.debug("")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data,
        // invalidate timers, and store enough application state
        // information to restore your application to its current
        // state in case it is terminated later.
        // If your application supports background execution,
        // this method is called instead of applicationWillTerminate: when the user quits.
        gLog.debug("")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive
        // state; here you can undo many of the changes made on entering the background.
        mControl.appWillEnterFore()
        gLog.debug("")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started)
        // while the application was inactive. If the application was previously
        // in the background, optionally refresh the user interface.
        gLog.debug("")
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate.
        // Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context 
        // before the application terminates.
        gLog.debug("")
    }
    
    func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication)
    {
        gLog.debug("")
    }
    
    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication)
    {
        gLog.debug("")
    }
    
    func application(_ application: UIApplication,
                      performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        gLog.debug("")
        // This is a nasty trick to buy us some more time (but not too much) from the OS.
        doBackgroundFetchLaunch()
        {
            (result) in
            completionHandler( result )
        }
    }

    func doBackgroundFetchLaunch(_ completion: ( ( _ result: UIBackgroundFetchResult ) -> Void )? )
    {
        gLog.debug("")
        let defs  = UserDefaults.standard
        let email = defs.string( forKey: StartSDK.scEmailKey )
        let pass  = defs.string( forKey: StartSDK.scPassKey )
        let host  = defs.string( forKey: ServerConnection.scApiHostname )
        let acl   = defs.bool( forKey: StartSDK.scAccessCodeLoginKey )
        if ( email != nil ) && ( pass != nil ) && ( host != nil ) {
            if let bm = mControl.becoManager {
                bm.setupServerInterface( user: email!, password: pass!, serverHost: host! )
                bm.beginScanning( skipRegister: true, isAccessCodeLogin: acl )
                {
                    (retStatus) in
                    switch( retStatus ) {
                    case .eBecoUnauthorized:
                        completion?( .failed )
                    default:
                        completion?( .newData )
                    }
                }
                
            }
        }
        else {
            // Don't hold for no reason.
            completion?( .noData )
        }
    }
    
}

