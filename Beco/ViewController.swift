//
//  ViewController.swift
//  Beco
//
//  Copyright © 2017 Beco Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

import XCGLogger

class ViewController: UIViewController, WKUIDelegate, PopupDelegate, BecoManagerDelegate, WKNavigationDelegate
{
    enum ActionState
    {
        case getstarted
        case refresh
    }
    enum CurrentPage
    {
        case startup
        case app
        case help
    }

    static let SCAN_STARTED             : String = "ScanStarted"
    static let EMAIL_KEY                : String = "UserEmail"
    static let scPages                  : String = "pages"

    fileprivate var startSDK            : StartSDK?
    
    fileprivate var webView             : WKWebView!

    @IBOutlet weak var activitySpinner  : UIActivityIndicatorView!
    @IBOutlet weak var toolBar          : UIToolbar!
    @IBOutlet weak var helpButton       : UIBarButtonItem!
    @IBOutlet weak var navButton        : UIBarButtonItem!
    @IBOutlet weak var btButton         : UIBarButtonItem!
    @IBOutlet weak var btAction         : UIBarButtonItem!

    fileprivate weak var mTimer     : Timer?
    
    //Beacons
    fileprivate var currHitBeacon   : String?  //Beacon we go the last hit for
    fileprivate var lastHitTime     : Double = 0.0 //Last time we had a hit
    fileprivate var lastLocChange   : Double = 0.0 //Last location change we received
    fileprivate var curPlace      : UUID?  //Place we got from the last location change for
    
    fileprivate var btEnabled       : Bool = false
    fileprivate var locEnabled      : Bool = false
    fileprivate var baseUrl         : String = ""
    fileprivate var reloadPending   : Bool = false  //reloads current url
    fileprivate var redrawPending   : Bool = false  //recalcs url etc and loads new url
    fileprivate var forceNotFoundPage : Bool = false  //We set this flag when we want to force the web view to a location not found page
    fileprivate var reloadTime      : Double!
    fileprivate var authPending     : Bool = false
    fileprivate var currentToken    : String?
    fileprivate var pageDrawn       : Bool = false
    fileprivate var restartScanning : Bool = false
    fileprivate var actionState     : ActionState = .getstarted
    fileprivate var missedLocationCount : Int = 0

    //Web Pages for the app
    fileprivate var startPage       : String?
    fileprivate var helpPage        : String?
    fileprivate var appPage         : String?
    fileprivate var scanHasStarted  : Bool = false
    
    fileprivate var currentPage     : CurrentPage = .startup
    
    var pendingStatusRect           : CGRect?
    var becoManager                 : BecoManager?

    
    
    static let scDisabledColor = UIColor( red:100.0/255.0, green:180.0/255.0, blue:252.0/255.0, alpha:0.5 )
    static let scEnabledColor = UIColor.white
    
    override func viewWillAppear(_ animated: Bool) {
        gLog.info("")
        self.navigationController?.navigationBar.isHidden = true
        if let becoSDK = becoManager?.becoInterface {
            // If we got here and SDK is running and if 'resigned active' then continue where we left off.
            if becoSDK.sdkState == .eBecoSdkStateScanning {
                gLog.info("skipping initial view")
                currentPage = .app
            }
        }
    }

    override func viewDidLoad()
    {
        gLog.info("")
        super.viewDidLoad()
        if let path = Bundle.main.path( forResource: "Initial", ofType: "plist" ) {
            if let dict = NSDictionary( contentsOfFile: path ) {
                let pagesDic = dict.object( forKey: ViewController.scPages ) as? [String: String]
                startPage = pagesDic?["startPage"]
                helpPage = pagesDic?["helpPage"]
                appPage = pagesDic?["appPage"]
                
            }
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        gLog.info("")
        super.viewDidAppear(animated)
        
        //Start the Beco SDK
        startSDK = StartSDK()
        
        if startSDK != nil {
            baseUrl = startSDK!.initSDK()
        }
        else {
            baseUrl = ""
        }
        
        setupWebView()
        scanHasStarted = UserDefaults.standard.bool(forKey: ViewController.SCAN_STARTED)
        
        //If we have started scanning before then skip the intro and go right to app page
        if scanHasStarted {
            startUp()
        } else {
            presentIntro()
        }
        
        reloadPending = false
        waitIndicatorOff()
    }
    
    /*
     *  setupWebView
     */
    func setupWebView() {
        gLog.info("")
        let newFrame = CGRect( x: 0, y: 0, width: view.frame.width, height: view.frame.height )
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView( frame: newFrame, configuration: webConfiguration )
        webView.uiDelegate = self
        webView.navigationDelegate = self
        redrawFrame()
        view.addSubview( webView )
        view.sendSubview(toBack: webView)
    }

    /* Show the intro pages **BEFORE** SKD is loaded and they are prompted to allow location services.
     *  This is a good spot to show the user a web page that details how BT and Location services are being used
     */
    func presentIntro() {
        gLog.info("")
        drawStartupPage()
    }

    func startUp()
    {
        gLog.info("")
        //Start the activity spinner
        view.bringSubview(toFront: activitySpinner)
        activitySpinner.startAnimating()
        
        actionState = .refresh
        btAction.title = "Refresh"
        becoManager = BecoManager()
        becoManager?.delegate = self
        
        startSDK!.startSDK(becoManager)
        UserDefaults.standard.set(true, forKey: ViewController.SCAN_STARTED)
        scanHasStarted = true;

        waitIndicatorOn()

        createTimer()
    }

    //Redraw the web view frame
    func redrawFrame()
    {
        let newFrame = CGRect( x: 0, y: 20, width: view.frame.width, height: view.frame.height)
        webView.frame = newFrame
    }

    // protocol PopupDelegate
    func makePopup( popupTitle: String, popupMessage: String, popupCompletion: ((UIAlertAction) -> Swift.Void)? )
    {
        if UIApplication.shared.applicationState != .background {
            let actionDisplay = UIAlertController(
                title: popupTitle,
                message: popupMessage,
                preferredStyle: .alert )
            let theAction = UIAlertAction( title: "OK", style: .default, handler: popupCompletion )
            actionDisplay.addAction( theAction )
            present(
                actionDisplay,
                animated: false,
                completion: nil )
        }
        else {
            // If in the background, just log an error.
            gLog.error("\(popupTitle)" + ": " + "\(popupMessage)")
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func appWillEnterFore()
    {
        self.navigationController?.navigationBar.isHidden = true
        // Force a "push" of the current location from the SDK.
        let becoSDK = becoManager?.becoInterface
        becoSDK?.pushLocationChange( nil )
    }

    func locationChanged(_ newBeacon: Beacon?)
    {
        if newBeacon != nil {
            gLog.debug("***** Location Change \(newBeacon!.id as String) ******")
            if curPlace != newBeacon!.place?.placeId {
                redrawPending = true;
                /*
                * Lets wait about 3 seconds to make sure a hit has happend before we send a change.  This will make sure
                * when the page refreshes that the occ api has the correct location from the last hit.  Too early and 
                * we will miss the location change.  If the apps seems to be missing the location change then you can up
                * this number a bit.  However this will make the change seem slower to the user so its a balance.
                */
                lastLocChange = CFAbsoluteTimeGetCurrent() + 3.0
                curPlace = newBeacon?.place?.placeId
            }
        } else {
            gLog.debug("***** NO LOCATION ******")
            curPlace = nil
            redrawPending = true
            reloadTime = CFAbsoluteTimeGetCurrent() + 1.0
        }
    }

    func hitReported(_ newBeacon: String )
    {
        gLog.debug( "hit: \(newBeacon)" )
        currHitBeacon = newBeacon
        lastHitTime = CFAbsoluteTimeGetCurrent()
    }

    func locationPermissionChanged(_ allowed: Bool) {
        gLog.debug( "locPerm: \(allowed)" )
        curPlace = nil
        reloadPending = true
        reloadTime = CFAbsoluteTimeGetCurrent() + 60.0
    }

    /**
     * createTime: starts the timer which keeps track of the users auth token timeout
     **/
    fileprivate func createTimer()
    {
        if mTimer != nil {
            #if DEBUG
                gLog.debug("destroy old timer")
            #endif
            mTimer?.invalidate()
        }
        mTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                      target: self,
                                      selector: #selector(ViewController.timerTick(_:)),
                                      userInfo: nil,
                                      repeats: true )
        gLog.debug("create timer")
    }
    
    /**
     *  timerTick - work that needs to be done at each tick like check the auth token etc.
     **/
    @objc fileprivate func timerTick( _ timer: Timer )
    {
        reloadTime = reloadTime == nil ? CFAbsoluteTimeGetCurrent() : reloadTime
        let now = CFAbsoluteTimeGetCurrent()

        //Handle getting the oAuth token
        if let expiresAt = ServerConnection.sharedInstance.user?.expiresAt {
            gLog.debug("Timer Check: now: \(now)  expiresAt: \(expiresAt)")
            if !authPending && (now >= expiresAt) {
                authPending = true
                gLog.debug("******* AUTH PENDING *******")
                ServerConnection.sharedInstance.startGetAuth(
                    {
                        (apiQueryResult) in
                        gLog.debug("*** Auth Back ****")
                        self.authPending = false
                        if apiQueryResult != .ok {
                            gLog.debug("error API result: \(apiQueryResult)")
                            // retry.
                            self.redrawPending = true
                            self.reloadTime = CFAbsoluteTimeGetCurrent() + 10.0
                        } else {
                            self.redrawPending = true
                            self.reloadTime = CFAbsoluteTimeGetCurrent() + 1.0
                        }
                    })
            }
        }
        
        if(!authPending) {
            //See if there is a new auth token and if there is then set the flag to redraw page
            if let token = ServerConnection.sharedInstance.user?.accessToken {
                if (token != currentToken) {
                    currentToken = token
                    gLog.debug("******* NEW AUTH RELOADING *******")
                    redrawPending = true
                }
            }
            if (redrawPending && lastHitTime >= lastLocChange) {
                //Redraw the page if flag is set
                //If there is a redrawPending and lastHitTime is greater than lastLoc then its safe to redraw.
                //If we don't wait for a hit we could redraw the wrong location since a hit updates the occ api.
                redrawPending = false
                waitIndicatorOn()
                pageDrawn = false
                drawAppPage()
            }
            
            //Reload the page if flag is set
            if (reloadPending && (now >= reloadTime)) {
                reloadPending = false
                waitIndicatorOff()
                reloadPage()
                
            }
            
        }
    }
    
    fileprivate func waitIndicatorOn () {
        btAction.isEnabled = false
        btAction.tintColor = UIColor.clear
        activitySpinner.isHidden = false
    }
    
    fileprivate func waitIndicatorOff () {
        activitySpinner.isHidden = true
        btAction.isEnabled = true
        btAction.tintColor = UIColor.white
    }

    //This simply refreshes the page - does not update URL so caching could be an issue
    //Call drawPage to cache bust
    fileprivate func reloadPage()
    {
        if !webView.isLoading {
            if UIApplication.shared.applicationState != .background {
                webView.reload()
            }
        }
    }

    //drawPage - draws the url and adds the url parameters that your app needs to call the occupancy API
    fileprivate func drawPage(_ url: String, _ needsAuth:Bool = false, _ needsHSID:Bool = false, _ needsTimeStamp:Bool = false, _ needsFakeHSID:Bool = false) {
        waitIndicatorOn()  //Will get set by WKNavigationDelate
        if (!pageDrawn && baseUrl != "")
        {
            let page = baseUrl + url
            if page.hasPrefix("http") || page.hasPrefix("https")  {
                var urlStr = page
                
                //Add the oAuth token to the url
                if(needsAuth) {
                    if let aToken = ServerConnection.sharedInstance.user?.accessToken {
                        urlStr += "?auth=\(aToken)"
                    }
                }
                //Add the Handset ID to the url
                if(needsHSID) {
                    if let idfv = UIDevice.current.identifierForVendor {
                        urlStr += "&hsid=\(idfv.uuidString)"
                    }
                }
                //Add a fake handset ID to the url
                if(needsFakeHSID) {
                    if let fakeUUID = NSUUID(uuidString:"00000000-0000-0000-0000-000000000000") {
                        urlStr += "&hsid=\(fakeUUID.uuidString)"
                    }
                }
                //Add a timestamp to the url to cache bust
                if(needsTimeStamp) {
                    let now = Int( CFAbsoluteTimeGetCurrent() )
                    urlStr += "&tm=\(now)"
                    
                }
                gLog.info( "Load: \(urlStr)" )
                let myURL = URL( string: urlStr )
                let myRequest = URLRequest( url: myURL! )
                webView.load( myRequest )
                pageDrawn = true
            }
        }
    }
    
    fileprivate func drawAppPage()
    {
        currentPage = .app
        pageDrawn = false;
        drawPage(appPage!, true, true, true, false)
    }

    //We call fake app page when we are not at a location - this will force it to show a not found page even if the occ still has you in 
    // an occupied location
    fileprivate func drawFakeAppPage()
    {
        currentPage = .app
        pageDrawn = false;
        drawPage(appPage!, true, false, true, true)
    }
    
    fileprivate func drawStartupPage() {
        currentPage = .startup
        pageDrawn = false
        drawPage(startPage!)
    }
    
    fileprivate func drawHelpPage() {
        currentPage = .help
        pageDrawn = false
        drawPage(helpPage!)
    }

    //Action button clicked - action button is in the middle of the toolbar at the botton of the screen
    // It is use on the Hello page and says "Get Started" and on the app page it is the "Refresh" button.
    @IBAction func getActionButtonClicked(_ sender: Any) {
         pageDrawn = false;
        // Figure out which page we should show.
        // At first startup we show "Get Started" after we simply show "Refresh"
        switch actionState {
        case .getstarted:
            startUp()
        case .refresh:
            waitIndicatorOn()
            self.reloadPending = false
            let now = CFAbsoluteTimeGetCurrent()
            if let user = ServerConnection.sharedInstance.user {
                user.expiresAt = now
            }
        }
    }

    // Help buton clicked
    // If we are on the app page we show help page.
    // If we are on the help page we show the app page.
    @IBAction func helpClicked( _ sender: AnyObject )
    {

        if(scanHasStarted && currentPage == .help) {
            drawAppPage()
        } else {
            drawHelpPage()
        }
    }

    //Location services button clicked
    @IBAction func navClicked( _ sender: AnyObject )
    {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: "App-Prefs:root=Bluetooth")!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: "App-Prefs:root=Bluetooth")!)
        }
    }

    //Bluetooth button prexsed
    @IBAction func btClicked( _ sender: AnyObject )
    {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
    
    //Callback after the webpage is loaded where we set the spinner off
    func webView(_ webView: WKWebView,didCommit navigation: WKNavigation!) {
        waitIndicatorOff()
    }

}
