//
//  User.swift
//  Beco
//
//  Copyright © 2015 Beco. All rights reserved.
//

import UIKit

// Encapsulates an authenticated user account
class User: NSObject
{

    enum Role
    {
        case user
        case manager
        case owner
        case admin
    }

    var email: String!
    var password: String!
    var clientId: String?
    var clientSecret: String?

    var accessToken: String?
    var refreshToken: String?
    var expiresAt: Double?

    var isAdmin: Bool
    {
        return roles.contains(.admin) || roles.contains(.owner) || roles.contains(.manager)
    }

    var roles = Set<Role>()

    init( email: String,
          password: String,
          clientId: String?,
          clientSecret: String? )
    {
        self.email = email
        self.password = password
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
}
