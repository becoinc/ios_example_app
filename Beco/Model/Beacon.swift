//
//  Beacon.swift
//  Beco
//
//  Copyright © 2015 Beco. All rights reserved.
//

import UIKit
import BecoSDK

class Beacon: NSObject
{

    enum BeaconType
    {
        case plain
        case sensor
        case invalid
        case otherAccount
    }

    var id: String!
    var name: String?

    var major: Int?
    var minor: Int?

    var uuid: String?

    var sensitivity: Int?

    var type: BeaconType! = .invalid

    var place: Place?

    init?( fromJson: NSDictionary )
    {
        let theBecoId = fromJson[ "becoId" ] as? String

        super.init()

        if theBecoId == nil {
            return nil
        }

        id = fromJson["becoId"] as! String
        name = fromJson["name"] as? String
        uuid = fromJson["proximityUUID"] as? String
        major = fromJson["trueMajor"] as? Int
        minor = fromJson["trueMinor"] as? Int
        sensitivity = fromJson["sensitivityAdjustment"] as? Int
        
        if sensitivity == nil {
            sensitivity = 0
        }
        type = .plain

        if (fromJson["place"] != nil) && (fromJson["place"] as? NSNull == nil) {
            place = Place( fromJson: fromJson["place"] as! NSDictionary )
        }
    }

    init( fromLocData: LocationData )
    {
        super.init()

        id   = fromLocData.becoId
        place = fromLocData.place

        if let place = place {
            name = place.placeName
        }
        else {
            name = "[unregistered]"
        }

        uuid = fromLocData.proximityUUID.uuidString
        
        major = Int( fromLocData.trueMajor )
        minor = Int( fromLocData.trueMinor )

        sensitivity = fromLocData.sensitivity
        
        type = .plain
    }
    
}
