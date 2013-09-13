var https = require('https');
var config = require('./config')

var foursquare = {};

foursquare.getVenue = function (id, response) {
  var foursquareURL = "https://api.foursquare.com/v2/venues/"
  + id + "?v=20130725"
  + "&client_id="+ config.foursquareClientId
  + "&client_secret=" + config.foursquareClientSecret;
  
  https.get(foursquareURL, function(res) {
    var body = '';

    res.on('data', function(chunk) {
        body += chunk;
    });

    res.on('end', function() {
        var venueObject = JSON.parse(body).response;
        response.render('venue', venueObject);
    });

  }).on('error', function(e) {
    console.log("Got error: " + e.message);
  });
}

module.exports = foursquare;
