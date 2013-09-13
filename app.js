require('nodetime').profile({
    accountKey: '0d1844b4095e39a16ee2f5faba46a93b0fb633af', 
    appName: 'Headto'
});

var express = require('express');
var config = require('./include/config')
var foursquare = require('./include/foursquare')

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

app.get('/venue/:id', function(request, response) {
  foursquare.getVenue(request.params.id, response);
});

var port = process.env.PORT || 5000;
app.listen(port, function() {
  console.log("Listening on " + port);
});

