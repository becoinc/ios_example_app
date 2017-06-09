#Beco iOS Example Shell App
This example app will give you a good starting point to create an application that leverages the Beco SDK and the Beco realtime occupancy API's.

##App Concept
This example app is designed to provide a Beco SDK enabled iOS reference app which provides is a simple WebView shell around a mobile ready web application.  This allows writing most if not all the app logic in a responsive web app that can be used across multiple device platforms.

<img src="https://raw.githubusercontent.com/becoinc/content_images/master/ios_shell_app/intro.png" style="width: 250px;"/>

### iOS Shell App
The app has a simple flow to authenticate the user and start the Beco SDK scanning and then to pass the needed information down to the web app so it then has enough information to access the Beco realtime API's.

###App Flow
####First App load
1. The app shows the starting page (pages/startPage from /Resources/Initial.plist).  At this point the Beco SDK has not been started and the user does not have an oAuth session.  This is a good place to explain to the user that you require location services to be on and they will be prompted for it.

<img alt="Beco hello page" src="https://raw.githubusercontent.com/becoinc/content_images/master/ios_shell_app/hello.png" style="width: 250px; padding-left: 30px; padding-bottom: 10px;"/>

2. User taps the "Get Started" button.  They are then prompted by iOS to allow Location Services to be used by this application.  If they allow it then the app will continue to the next phase.

<img alt="Beco Location Services" src="https://raw.githubusercontent.com/becoinc/content_images/master/ios_shell_app/LocationServices.png" style="width: 250px; padding-left: 30px; padding-bottom: 10px;"/>

3. The Beco SDK is started and the handset is registered with Beco and is also granted an oAuth token to pass to the web app for API authentication.

<img alt="Beco app page" src="https://raw.githubusercontent.com/becoinc/content_images/master/ios_shell_app/LocationFound.png" style="width: 250px; padding-left: 30px; padding-bottom: 10px;"/>

####Subsequent App Loads after SDK has started scanning
1. The user is taken immediately to the app page with the SDK scanning.

<img alt="Beco hello page" src="https://raw.githubusercontent.com/becoinc/content_images/master/ios_shell_app/LocationFound.png" style="width: 250px; padding-left: 30px; padding-bottom: 10px;"/>

####While the app is scanning
1. There is a timer loop that is started in ```ViewControler.TimerTick``` which fires every second.  This is the main control loop.  Most of the logic that redraws the web app page is located in this spot in the app. 
2. When SDK raises a location change event the app ```ViewController.locationChange``` event is called. Which then sets a flag that tells the timer on next tick to refresh the web app page. There is no need to pass to the location id or beacon id down to the web app. By polling the realtime API's with the handset id (hsid) you will get the current location back with much more information about the place the user is located.

##Configuration Information

####```/Resources/Initial.plist``` configuration file
This file contains all the configuration settings the app needs to start the Beco SDK scanning and to access the realtime APIs from the web app.
|Resource Key   |Description   |Default Setting   |
|-|-|-|
|email|The email or system account used to establish the oAuth session which is passed down to the web app for use to access the Beco realtime API's.  Contact hello@beco.io to receive a system account if you have not already received one.||
|password|The password used to establish the oAuth session.||
|clientId|The client id the Beco SDK uses to establish a session with the Beco servers while it is scanning for beacons. Contact hello@beco.io to receive these credentials.||
|clientSecret|The client secret the Beco SDK uses to establish a session with the Beco servers while it is scanning for beacons. Contact hello@beco.io to receive these credentials.||
|apiHostname|The Beco API host.  You should not change this unless instructed by the Beco support team.|api.beco.io|
|baseUrl|The base url of *your* web app that will be shown within the sell app (https://yourwebapp.com).||
|pages/startPage|The initial page that is shown to the user *before* the user is prompted to allow access to Location Services (which is required by the Beco SDK).|/hello.html|
|pages/helpPage|The help page that is shown when the user taps the "Help" icon on the app toolbar|/help.html|
|pages/appPage|The primary page that is shown while the app is scanning for location changes.  When the app detects a location change it refreshes this page with a valid oAuth token and the users handset id (hsid).  This page should be your major focus of development.|/index.html|

##Get Started
###Get the source code
Fork this repo or download the code to your local development environment.
###Setup the Web App
See the ```/ExampleWebApp/README.md```
###Build the iOS App
- Update /Resources/Initial.plist with the correct values. Particularly the credentials and the baseUrl.
- Connect an iOS device and run the code. **You need to use a real device that is near a beacon for it to fully work correctly.**
