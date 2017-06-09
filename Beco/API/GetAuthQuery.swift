//
//  GetAuth.swift
//  Beco
//
//  Copyright © 2017 Beco. All rights reserved.
//


import UIKit

class GetAuthQuery: BecoAPIQuery
{

    static let scTokenExpirationMargin = 60.0      // leave 20s as a "buffer"

    var user: User?

    func set( user: User )
    {
        self.user = user
    }

    override func getAPIURL() -> String
    {
        return "/oauth/token"
    }

    override func getHttpMethod() -> String
    {
        return "POST"
    }

    override func getUseJson() -> Bool
    {
        return false
    }

    override func getPOSTContents() -> [String:String]
    {
        var retVal = [String:String]()

        if user != nil && user!.clientId != nil && user!.clientSecret != nil {
            retVal[ "username" ] = "\(user!.email as String)"
            retVal[ "password" ] = "\(user!.password as String)"
            retVal[ "grant_type" ] = "password"
            retVal[ "client_id" ] = "\(user!.clientId! as String)"
            retVal[ "client_secret" ] = "\(user!.clientSecret! as String)"
        }

        return retVal
    }

    override func handleResponse(_ json: NSDictionary) -> Bool
    {
        if user != nil {
            user!.accessToken = json["access_token"] as? String
            user!.refreshToken = json["refresh_token"] as? String
            if let expires = (json["expires_in"] as? Double) {
                let now = CFAbsoluteTimeGetCurrent()
                user!.expiresAt = now + expires - GetAuthQuery.scTokenExpirationMargin
            }
        }
        return true
    }
    
}
