import urllib, json
from flask import Flask, render_template, request

app = Flask(__name__)

def geolocate_ip(ip):
	f = urllib.urlopen("http://ipinfo.io/" + ip + "/json")   
	
	j = json.loads(f.read())
	#   print json.dumps(j, sort_keys=True, indent=4, separators=(',', ': '))
	
	return j.get('loc')

def search_location(query):
	url = "https://api.foursquare.com/v2/venues/search?"
	ip = request.remote_addr
	loc = geolocate_ip(request.remote_addr)
	
	if (len(loc) > 5):
		print "Local search"
		params = urllib.urlencode({"client_id":"EBA5MTZIPRVHNGKU2RB4KZ45J2BAOZFSYIXHGYBGR1KIXFIQ", "client_secret":"K0CBX5TQKHNEB35MGT3NNIVLWP0C4L0CQQ4UP3C2LUSLQL0W", "query":query, "v":"20130725", "limit":"5", "ll":loc })
	else:
		print "Global search"
		params = urllib.urlencode({"client_id":"EBA5MTZIPRVHNGKU2RB4KZ45J2BAOZFSYIXHGYBGR1KIXFIQ", "client_secret":"K0CBX5TQKHNEB35MGT3NNIVLWP0C4L0CQQ4UP3C2LUSLQL0W", "query":query, "v":"20130725", "limit":"5", "intent":"global" })
			
	f = urllib.urlopen(url + params)   
	j = json.loads(f.read())
	#print json.dumps(j, sort_keys=True, indent=4, separators=(',', ': '))
			
	send_back = []
	for i in j.get('response').get('venues'):
		venue = {"name" : i.get('name'), "country" : i.get('location').get('country'), "city" : i.get('location').get('city'), "lat" : i.get('location').get('lat'), "lng" : i.get('location').get('lng') }
		send_back.append(venue)  
	return send_back
			
@app.route("/")
def hello():
	searchword = request.args.get('query')
	if searchword:
		venues_list = search_location(searchword)
		return render_template('index.html', venues_list=venues_list)
	else:
		return render_template('index.html')        
				
if __name__ == "__main__":
	app.debug = True
	app.run(host='0.0.0.0')