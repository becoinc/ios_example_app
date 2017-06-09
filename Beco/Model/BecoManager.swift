//
//  BecoManager.swift
//  Beco
//
//  Copyright © 2017 Beco. All rights reserved.
//

import UIKit
import BecoSDK
import CoreLocation

protocol BecoManagerDelegate
{
    
    func locationChanged(_ beacon: Beacon? )

    func hitReported(_ becoId: String )

    func locationPermissionChanged( _ allowed: Bool )
}

class BecoManager: NSObject, BecoSDKDelegate
{
    //How many times in a row do we get nil location change events before we trust it - 1 = ~10 seconds.
    //Make sure ?timeWindow on /occupancy/location/ is set to below this value (sample html code has it set at 30 seconds)
    let maxNoLocationCalls = 4
    
    var locationTypes: [LocationType] = []
    var placeTypes: [PlaceType] = []
    var locations: [Location] = []
    var locTypeToPlaceType = [ LocationType : [PlaceType] ]()
    var placeEnumStringToPlaceType = [ String : PlaceType ]()
   
    var delegate: BecoManagerDelegate?
    
    var becoInterface: BecoSDKInterface
    
    var nameToLocation = [ String : Location ]()
    var customerUserId: String?
    var lastLocation: UUID?
    var missedLocationCount: Int = 0  //Counter which tracks beacon misses
    
    var mStartScanCompletion: ( ( BecoSDKReturnStatus ) -> Void )?
    
    override init()
    {
        becoInterface = BecoSDK.BecoSDKInterface()
        
        super.init()
    }
    
    func setupServerInterface( user: String, password: String, serverHost: String )
    {
        customerUserId         = user
        becoInterface.hostname = serverHost
        becoInterface.setCredentials( user, plainPw: password )
    }
    
    func beginScanning( skipRegister: Bool,
                        isAccessCodeLogin: Bool,
                        completion: ( ( BecoSDKReturnStatus ) -> Void )? )
    {        
        gLog.debug( "Begin Scanning: skipRegister: \(skipRegister) isAccessCodeLogin: \(isAccessCodeLogin)" )
        
        var personId: String? = nil
        
        self.mStartScanCompletion = completion
        
        if isAccessCodeLogin {
            personId = nil
        }
        else {
            personId = nil
        }
        
        if !skipRegister {
            _ = becoInterface.registerHandset( nil,
                                               personId: personId,
                                               groupId: nil,
                                               userData: nil )
                {
                    (success, data) in
                    
                    if ( success ) {
                        // on a 409 conflict (already exists)
                        // success is true, but the RHR is nil.
                        gLog.debug("Registered Handset: \(data?.becoHSID.description ?? "No-HANDSET")")
                    }
                    else {
                        gLog.error("Registering Handset Failed.")
                        self.mStartScanCompletion?( BecoSDKReturnStatus.eBecoNetworkError )
                        return
                    }
                }
        }

        // This probably won't throw b/c we've set the credentials and hostname above.
        // If it throws then it is only because of user credentials. Other failures or success call 'completion'.
        becoInterface.delegate = self
        do {
            try becoInterface.startScan()
        }
        catch InvalidCredentialsException.notSet( let fieldName ) {
            gLog.error("Failure: \(fieldName)")
            self.mStartScanCompletion?( BecoSDKReturnStatus.eBecoCredentials )
        }
        catch {
            gLog.error("Failure: <other>")
            self.mStartScanCompletion?( BecoSDKReturnStatus.eBecoCredentials )
        }
    }

    func stopScan()
    {
        gLog.warning( "Stop Scanning Unimplemented." )
        // There is no logout or other provision to switch users
        // so we don't do it.
    }
        
    // MARK: BecoSDK Delegate ----------------------------------------------
    func becoSdkDelegate( receiveLocationData locationData: LocationData? )
    {
        gLog.debug("Locaction Change From SDK: \(locationData?.becoId ?? "nil")")
        
        //We will get nil if the handset has moved out of range of the beacons (left the building)
        if(locationData == nil) {
            //We want to filter out the occasional missed location
            if(missedLocationCount >= maxNoLocationCalls) {
                gLog.debug("**** Missed Location (\(missedLocationCount) of \(maxNoLocationCalls)) SENDING NO LOCATION **********")
                lastLocation = nil
                delegate?.locationChanged( nil )
                missedLocationCount = 0
            } else {
                gLog.debug("**** Missed Location (\(missedLocationCount) of \(maxNoLocationCalls)) **********")
                missedLocationCount += 1
            }
        }
        else {
            missedLocationCount = 0
            
            //Only change if we have a different place id (a group of beacons)
            if (lastLocation == nil || lastLocation != locationData?.place?.placeId) {
                lastLocation = locationData?.place?.placeId
                delegate?.locationChanged( Beacon( fromLocData: locationData! ) )
            }
        }
    }

    func becoSdkDelegate( reportError error: BecoSDKErrorCode )
    {
        gLog.debug("**** SDK Error **********")
        switch error {
        case .credentialMismatch, .customerNotFound:
            delegate?.locationChanged( nil )
            break
        case .rateLimitExceeded:
            break
        case .serverCommunicationFailure:
            delegate?.locationChanged( nil )
            break
        case .locationEnabled:
            delegate?.locationPermissionChanged( true )
            break
        case .locationDisabled:
            delegate?.locationPermissionChanged( false )
            break
        default:
            break
        }
    }

    func becoSdkDelegate( reportAppHit becoId: String )
    {
        gLog.debug("**** Hit Reported: \(becoId) **********")
        delegate?.hitReported( becoId )
    }

    /**
     * Called to indicate start scan has completed.
     */
    func becoSdkDelegate(reportStartScanComplete: BecoSDKReturnStatus) {
        self.mStartScanCompletion?( reportStartScanComplete )
    }
    
    // MARK: End BecoSDK Delegate ------------------------------------------

}
