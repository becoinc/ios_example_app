//
//  LocationType.swift
//  Beco
//
//  Created by Jeffrey Zampieron on 1/22/16.
//  Copyright © 2016 Beco. All rights reserved.
//

import Foundation

class PlaceType : Equatable, Hashable
{
    static func SortByEnumValue( left: PlaceType, right: PlaceType ) -> Bool
    {
        if left.enumVal == "PLACE_TYPE_OTHER"
        {
            return false
        }
        if right.enumVal == "PLACE_TYPE_OTHER"
        {
            return true
        }
        return left.enumVal.uppercaseString < right.enumVal.uppercaseString
    }
    
    static func SortByDesc( left: PlaceType, right: PlaceType ) -> Bool
    {
        if left.enumVal == "PLACE_TYPE_OTHER"
        {
            return false
        }
        if right.enumVal == "PLACE_TYPE_OTHER"
        {
            return true
        }
        return left.desc.lowercaseString < right.desc.lowercaseString
    }

    var desc    : String
    var enumVal : String
    var enabled : Bool
    
    var locationTypes: [LocationType] = []
    
    var hashValue : Int
    {
        return self.desc.hashValue
    }
    
    init( locationType: LocationType )
    {
        // This is used in case the server provides stupid information,
        // for example: A location type of Transportation 
        // which has no place types with it.
        // Basically this is a dummy object.
        self.desc = "UNKNOWN"
        self.enumVal = "UNKNOWN"
        self.enabled = false
        self.locationTypes.append( locationType )
    }
    
    init( fromJson: NSDictionary )
    {
        self.desc    = fromJson[ "desc" ] as! String
        self.enumVal = fromJson[ "enumVal" ] as! String
        self.enabled = fromJson[ "enabled" ] as! Bool
        
        let locTypes = fromJson[ "locationTypes" ] as? NSArray
        if( locTypes != nil )
        {
            for aLocType in locTypes!
            {
                let aLocTypeObj = LocationType( fromJson: aLocType as! NSDictionary )
                if aLocTypeObj.enabled
                {
                    self.locationTypes.append( aLocTypeObj )
                }
            }
        }
        
    }
    
}

@warn_unused_result func==(lhs: PlaceType, rhs: PlaceType ) -> Bool
{
    return lhs.desc == rhs.desc && lhs.enumVal == rhs.enumVal
}