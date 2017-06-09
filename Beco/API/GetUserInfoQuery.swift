//
//  GetUserInfoQuery.swift
//  Beco
//
//  Created by Matt Spong on 4/3/16.
//  Copyright © 2016 Beco. All rights reserved.
//

import UIKit

class GetUserInfoQuery: BecoAPIQuery
{

    var roles = Set<User.Role>()

    override func getAPIURL() -> String
    {
        return "/2.0/users"
    }

    override func handleResponse(_ json: NSDictionary) -> Bool
    {
        roles.removeAll()

        let jsonRoles = json["roles"] as? [NSDictionary]

        if jsonRoles != nil {
            for role in jsonRoles! {
                switch role["roleName"] as! String {
                case "CUSTOMER_OWNER":
                    roles.insert(.owner)
                case "CUSTOMER_MANAGER":
                    roles.insert(.manager)
                case "CUSTOMER_USER":
                    roles.insert(.user)
                case "ADMIN":
                    roles.insert(.admin)
                default:
                    gLog.error("Unknown role \(role["roleName"] as! String)")
                }
            }
        }
        
        return true
    }
    
}
