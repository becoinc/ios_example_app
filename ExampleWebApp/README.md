# Example Web App
This example app is designed to work with the Beco example shell App. It gathers the appropriate url parameters and makes a call to the Beco Occupancy API to determine the users current location.

## The files:
### index.html
This page is for the /pages/appPage entry in the /Resources/Initial.plist file in the Example iOS app. This is the main page of the app while the user is scanning for locations.  This page will be show when the user is using the app.  It shows the user their current location.

### hello.html
This page is for the /pages/startPage entry in the /Resources/Initial.plist file in the Example iOS app.  This is the first page a user sees when they access the app for the first time.  It will not be shown after the initial load of the app and the user has tapped the "Get Started" button in the app.

## help.html
This page is for the /pages/helpPage entry in the /Resources/Initial.plist file in the Example iOS app.  This is the page a user will see when they press the help icon in the iOS app toolbar.

## main.js
This is the main javascript file that is included in the index.html file.  Its has the code used to pull the url parameters and use them to call the Beco Occupancy API to gather reatime occupancy data on the current handset.  

### help.html
This is the help page that is show when the user taps the 

## Run the locally using a [Webpack](https://webpack.js.org/) development server
Make sure you have a current version of [node.js](https://nodejs.org) installed.

From this directory run the following commands:

```npm install```

```npm start```

This will install some basic dependencies including the Webpack development server which you can use to run the example if you do not have a webserver you can drop the code onto.  The second command will start the Webpack development server for you on ```localhost:3000```

You should now be able to browse to ```localhost:3000``` and see the example page (without data).

To have the Example App access your local dev machine both your device and your local webserver needs to be accessible over your local network. If they are not accessible to each other you may want to use a service such as [ngrok](https://ngrok.com/) to help with development.

## Build the example to run on your own webserver
Make sure you have a current version of [node.js](https://nodejs.org) installed.

From this directory run the following commands:

```npm install```

```npm run build```

Copy the contents of the ```/dist``` directory to your webserver.
