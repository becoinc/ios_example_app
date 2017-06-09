//
//  StartSDK.swift
//  Beco
//
//  Copyright © 2017 Beco. All rights reserved.
//

import Foundation
import BecoSDK

protocol PopupDelegate
{
    
    func makePopup( popupTitle: String, popupMessage: String, popupCompletion: ((UIAlertAction) -> Swift.Void)? )
    
}

class StartSDK
{

    static let scEmailKey           = "email"
    static let scPassKey            = "password"
    static let scAccessCodeLoginKey = "accessCodeLogin"
    static let scClientIdKey        = "clientId"
    static let scClientSecretKey    = "clientSecret"
    static let scBaseUrl            = "baseUrl"
    
    var server: String?             = ""
    var email: String?              = ""
    var password: String?           = ""
    var clientId: String?           = ""
    var clientSecret: String?       = ""
    var baseUrl: String?            = ""
    var isBackground                = false
    var becoManager                 : BecoManager?


    var mPopupDel : PopupDelegate?

    fileprivate var popupTitle: String!
    fileprivate var popupMessage: String!
    fileprivate var popupCompletion: ((UIAlertAction) -> Swift.Void)!
    
    func initSDK() -> String {
         if let path = Bundle.main.path( forResource: "Initial", ofType: "plist" ) {
            if let dict = NSDictionary( contentsOfFile: path ) {
                //Grab the settings from Resources/Inital.plist
                self.server = dict.object( forKey: ServerConnection.scApiHostname ) as? String
                self.email = dict.object( forKey: StartSDK.scEmailKey ) as? String
                self.password = dict.object( forKey: StartSDK.scPassKey ) as? String
                self.clientId = dict.object( forKey: StartSDK.scClientIdKey ) as? String
                self.clientSecret = dict.object( forKey: StartSDK.scClientSecretKey ) as? String
                self.baseUrl = dict.object( forKey: StartSDK.scBaseUrl ) as? String

                //Check email and password and return if not found
                if self.email == "" {
                    gLog.error( "User not found." )
                    return self.baseUrl ?? ""
                }
                
                gLog.info( "User: \(self.email ?? "No Email")")
                if (self.password == "") {
                    gLog.error( "Password not found." )
                    return self.baseUrl ?? ""
                }

            self.isBackground = !(UIApplication.shared.applicationState != .background)
            if !self.isBackground {
                gLog.debug("Foreground start.")
            }
            else {
                gLog.debug("Background start.")
            }

            return self.baseUrl ?? ""
            }
        }
        return ""
    }
    
    func startScanning( _ manager: BecoManager?) {
        gLog.info("")
        manager!.beginScanning(
            skipRegister: self.isBackground,
            isAccessCodeLogin: false,
            completion: self.uiProcessStartScanResult)
    }
      
    func startSDK( _ manager: BecoManager?)
    {
        gLog.info("")
        self.becoManager = manager
        ServerConnection.sharedInstance.login(
            manager: manager!,
            server: self.server!,
            email: self.email!,
            password: self.password!,
            clientId: self.clientId,
            clientSecret: self.clientSecret,
            completion:
            {
                (apiQueryResult) in
                if apiQueryResult != .ok {
                    gLog.debug("error API result: \(apiQueryResult)")
                    self.loginFailure( apiQueryResult )
                }
                else {
                    self.startScanning(manager)
                    
                }
        })
    }
    
    fileprivate func doPopup()
    {
        if mPopupDel != nil {
            mPopupDel?.makePopup( popupTitle: popupTitle,
                                  popupMessage: popupMessage,
                                  popupCompletion: popupCompletion )
        }
    }
    
    fileprivate func loginFailure( _ result: BecoAPIQuery.Result )
    {
        popupTitle = "Login failed"
        
        switch result {
        case .noInternet:
            popupMessage = "No internet connection"
        case .dnsFailed:
            popupMessage = "DNS lookup failed"
        case .connectionFailed:
            popupMessage = "Can't connect to server"
        default:
            popupMessage = "Invalid username or password"
        }
        
        popupCompletion =
        {
            (alertItem) in
        }
        
        doPopup()
    }
    
    fileprivate func uiProcessStartScanResult( _ result: BecoSDKReturnStatus )
    {
        var bBluetoothOff: Bool = false
        var bHandlePopup: Bool = false
        
        switch result {
            
        case .eBecoSuccess:
            gLog.debug("Start Scan Success.")
            
        case .eBecoUnauthorized:
            gLog.debug("Location Not Authorized Yet.")
            bHandlePopup = true
            popupTitle = "Location Unauthorized"
            popupMessage = "Please set Location to Always in iOS Settings for the Beco App."
            popupCompletion =
            {
                (alertItem) in
                // The SDK will handle this on its own.
                // Don't stop scanning
                //self.handleLogout(self.becoManager!)
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: "App-Prefs:root=Location")!, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(URL(string: "App-Prefs:root=Location")!)
                }            }
            
        case .eBecoBluetoothOff:
            bBluetoothOff = true
            
        case .eBecoBluetoothUnsupported:
            bBluetoothOff = true
            
        case .eBecoBluetoothUnauthorized:
            bBluetoothOff = true
            
        case .eBecoBluetoothUnknown:  // General error state, retry 'soon'?
            bBluetoothOff = true
            
        case .eBecoNetworkError:
             gLog.debug("Network Error.")
            bHandlePopup = true
            popupTitle = "Communication Error"
            popupMessage = "Please verify internet connectivity."
             // The SDK will handle this on its own.
             // Don't stop scanning
             popupCompletion = nil
             break
        case .eBecoCredentials:
            bHandlePopup = true
            popupTitle = "Communication Error"
            popupMessage = "Missing credentials for network."
            popupCompletion =
            {
                (alertItem) in
                // b/c you can't generate hits or make any other Beco API
                // calls if this happens.
            }
            
        case .eBecoAlreadyScanning:
            gLog.debug("Already Scanning.")
        }
        
        if bBluetoothOff {
            bHandlePopup = true
            popupTitle = "Turn Bluetooth On"
            popupMessage = "Please turn Bluetooth On for the Beco App to function."
            popupCompletion =
            {
                (alertItem) in
            }
        }
        
        if bHandlePopup {
            doPopup()
            // If got a popup that wasn't for Bluetooth off, then it is an error.
            if !bBluetoothOff {
                gLog.error(" Status: \(result.rawValue) ")
            }
        }
    }
    
}
