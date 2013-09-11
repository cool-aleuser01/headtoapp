var express = require('express');
var jade = require('jade');
var config = require('./config')

var app = express();
app.set('view engine', 'jade');
app.set('view options', {layout: false});

app.use(express.logger());
app.use(express.bodyParser());
app.use(express.cookieParser());
app.use(app.router);
app.use(express.static('public'));
app.use(express.favicon());
//app.use(express.errorHandler());

//app.get('/', function(request, response) {
//});

app.post('/login', function(request, response){
  var data = request.body;
  mdb.users
    .find({nickname: data.nickname})
    .toArray(function(err, doc) {   
	  if(!(doc != 0)) { 
	    response.render('index', {flash: 'No user found'}); 
	  } else if(doc[0].password != data.password) { 
	    response.render('index', {flash: 'Wrong password'}); 
	  } else {
        request.session.user = doc[0].nickname;
        response.redirect('/');
	  }
    }); 
});

var port = process.env.PORT || 3000;
app.listen(port, function() {
  console.log("Listening on " + port);
});

