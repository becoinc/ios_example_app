//
//  Logging.swift
//
//  Copyright © 2017 Beco Inc. All rights reserved.
//

import XCGLogger
import Foundation
import BecoSDK

/**
 * Used to set the logging level of the Beco SDK.
 *
 * Should be left as INFO unless otherwise advised by Beco engineering.
 */
let gLog = XCGLogger( identifier: "com.beco.ios.XCGLog.main" )

fileprivate let scDebugLogLevel = XCGLogger.Level.debug

func setupLogger( log: XCGLogger, cacheDir: URL )
{
    //let formatDate = DateFormatter()
    //formatDate.dateFormat = "yyMMddhhmma"
    let logPath: URL = cacheDir.appendingPathComponent( "applog-\(BecoSDKInterface.getSDKVersion()).log" )
    log.setup( level: .info,
               showLogIdentifier: true,
               showFunctionName: true,
               showThreadName: true,
               showLevel: true,
               showFileNames: true,
               showLineNumbers: true,
               showDate: true )
    // This is _not_ the XCGLogger default instance.
    #if DEBUG
        log.outputLevel = scDebugLogLevel
    #else
        log.outputLevel = .info
    #endif
    
    #if DEBUG
        // Create a file log destination
        let fileDestination = AutoRotatingFileDestination( writeToFile: logPath,
                                                           shouldAppend: true )
        
        // Set the file size limit - 10MB
        fileDestination.targetMaxFileSize = 1 * 1024 * 1024
        fileDestination.targetMaxLogFiles = 5
        
        // Optionally set some configuration options
        fileDestination.outputLevel = scDebugLogLevel
        fileDestination.showLogIdentifier = false
        fileDestination.showFunctionName = true
        fileDestination.showThreadName = true
        fileDestination.showLevel = true
        fileDestination.showFileName = true
        fileDestination.showLineNumber = true
        fileDestination.showDate = true
        
        // Process this destination in the background
        fileDestination.logQueue = XCGLogger.logQueue
        
        // Add the destination to the logger
        log.add(destination: fileDestination)
    #else
        // TODO - We should add an SDK function to upload the logs
        // to Beco for debugging.
        // Until then, its useless to write any log files.
    #endif
 
    // Add basic app info, version info etc, to the start of the logs
    log.logAppDetails()
}
