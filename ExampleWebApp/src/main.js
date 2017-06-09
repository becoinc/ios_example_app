// Expects URL to have the following parameters
// http://localhost:3000/?auth=[oauth token]&hsid=[handset id]

var becoAPI = 'https://api.beco.io';
var occEndPoint = '/3.0/occupancy/handset';

//Get url parameters
function getParam( name, url ) {
    if (!url) url = location.href;
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regexS = "[\\?&]"+name+"=([^&#]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( url );
    return results == null ? null : results[1];
}

//Succes
function onSuccess(data) {
  if(data.beacon === null) {
    showPlaceInfo('NOT FOUND','','')
  } else {
    showPlaceInfo(data.beacon.location,data.beacon.becoId,data.beacon.name)
  }

}

//failure
function onError(error) {
  showPlaceInfo('','', 'ERROR: ' + error.statusText)
}

function showPlaceInfo(locationName, becoId, placeName) {
  var elLocation = document.getElementById('location');
  var elPlaceName = document.getElementById('place');
  var elBecoId = document.getElementById('becoId');
  elLocation.innerHTML = locationName;
  elPlaceName.innerHTML = placeName;
  elBecoId.innerHTML = becoId;

}

function showParams(auth, hsid) {
  var elHsid = document.getElementById('hsid');
  var elAuth = document.getElementById('auth');
  var elUpdated = document.getElementById('updated');
  var currentDate = Date();
  elHsid.innerHTML = hsid;
  elAuth.innerHTML = auth;
  elUpdated.innerHTML = currentDate.toLocaleString();
}

function updateLocation() {
  var hsid = getParam('hsid', location.search);
  var auth = getParam('auth', location.search);

  showParams(auth, hsid);

  if(hsid.indexOf('000000') > -1) {
    showPlaceInfo('NOT FOUND','','')
  } else {
    var url = becoAPI + occEndPoint + '/' + hsid;
    $.ajax({
      method: 'GET',
      url: url,
      headers: {
        'Authorization': 'bearer ' + auth
      },
      data: {
        fastAquire: true,
        timeWindow: 30000
      },
      success: onSuccess,
      error: onError
    })
  }
}

updateLocation();
