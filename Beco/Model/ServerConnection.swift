//
//  ServerConnection.swift
//  Beco
//
//  Copyright © 2015 Beco. All rights reserved.
//

import UIKit

class ServerConnection: NSObject, URLSessionDataDelegate
{

    static let scApiHostname = "apiHostname"

    static let sharedInstance = ServerConnection()
    static var serverHost = "api.beco.io"           // the default
    static var session: Foundation.URLSession?
    var user: User?

    fileprivate let backgroundQueue = DispatchQueue.global( qos: DispatchQoS.QoSClass.default )

    override init()
    {
        super.init()
    }

    func login(
        manager: BecoManager?,
        server: String?,
        email: String,
        password: String,
        clientId: String?,
        clientSecret: String?,
        completion: @escaping (BecoAPIQuery.Result) -> Void)
    {
        let defs = UserDefaults.standard
        let defaultHostname = defs.object( forKey: ServerConnection.scApiHostname )
        if server != nil {
            ServerConnection.serverHost = server!
            defs.set( ServerConnection.serverHost, forKey: ServerConnection.scApiHostname )
        }
        else if defaultHostname != nil {
            ServerConnection.serverHost = defaultHostname as! String
        }
        gLog.info("Using Server Host: \(ServerConnection.serverHost)")
        
        manager?.setupServerInterface(
            user: email,
            password: password,
            serverHost: ServerConnection.serverHost)

        backgroundQueue.async
        {
            self.user = User( email: email, password: password, clientId: clientId, clientSecret: clientSecret )
            let config = URLSessionConfiguration.ephemeral
            
            ServerConnection.session = Foundation.URLSession( configuration: config, delegate: self, delegateQueue: nil )
            gLog.info("begin session")
            self.startGetAuth( completion )

        }
    }
    
    func validateLogin(
        server: String?,
        email: String,
        password: String,
        clientId: String?,
        clientSecret: String?,
        completion: @escaping (BecoAPIQuery.Result) -> Void)
    {
        let defs = UserDefaults.standard
        let defaultHostname = defs.object( forKey: ServerConnection.scApiHostname )
        if server != nil {
            ServerConnection.serverHost = server!
            defs.set( ServerConnection.serverHost, forKey: ServerConnection.scApiHostname )
        }
        else if defaultHostname != nil {
            ServerConnection.serverHost = defaultHostname as! String
        }
        gLog.info("Using Server Host: \(ServerConnection.serverHost)")
        
        backgroundQueue.async
            {
                self.user = User( email: email, password: password, clientId: clientId, clientSecret: clientSecret )
                let config = URLSessionConfiguration.ephemeral
                
                ServerConnection.session = Foundation.URLSession( configuration: config, delegate: self, delegateQueue: nil )
                gLog.info("begin session")
                self.startGetAuth( completion )
                
        }
    }

    func logout()
    {
        ServerConnection.session?.invalidateAndCancel()
    }

    func startGetAuth(_ completion: @escaping (BecoAPIQuery.Result) -> Void )
    {
        if ServerConnection.session != nil {
            if let user = self.user {
                if user.clientId == nil || user.clientSecret == nil {
                    gLog.error("error missing - clientId or clientSecret")
                    completion(.queryFailed)
                }
                else {
                    let request = GetAuthQuery()
                    request.set( user: user )
                    request.makeRequest()
                    {
                        (result) in
                        if( result == .ok ) {
                            gLog.info("Get Auth OK")
                            completion( .ok )
                        }
                        else {
                            gLog.error("Get Auth failed")
                            completion( result )
                        }
                    }
                }
            }
        }
    }

    // MARK: NSURLSessionDataDelegate

    func urlSession( _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        // Allow arbitrary loads overrides only the following (info.plist)
        // http://stackoverflow.com/questions/34035743/allow-arbitrary-loads-does-not-work-in-ios-9-1-simulator
        // 1. The prohibition on HTTP requests
        // 2. The key length and encryption type requirements for HTTPS
        // This allows anything.
        completionHandler( Foundation.URLSession.AuthChallengeDisposition.useCredential,
            URLCredential( trust: challenge.protectionSpace.serverTrust! ) )
    }

}

