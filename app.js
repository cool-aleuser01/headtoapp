var express = require('express');
var https = require('https');
var config = require('./config')

var app = express();
app.set('view engine', 'hjs');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(app.router);
app.use(express.static('public'));
app.use(express.errorHandler());

app.get('/', function(request, response) {
  response.render('index');
});

function getVenue(id, response) {
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
        console.log(JSON.stringify(venueObject));
        response.render('venue', venueObject);
    });

  }).on('error', function(e) {
    console.log("Got error: " + e.message);
  });
}

app.get('/venue/:id', function(request, response) {
  getVenue(request.params.id, response);
});

var port = process.env.PORT || 3000;
app.listen(port, function() {
  console.log("Listening on " + port);
});

