require "sinatra"
require 'koala'
require "foursquare2"
require "net/https"
require "uri"
require "fiber"

enable :sessions
set :raise_errors, false
set :show_exceptions, false

# Scope defines what permissions that we are asking the user to grant.
# In this example, we are asking for the ability to publish stories
# about using the app, access to what the user likes, and to be able
# to use their pictures.  You should rewrite this scope with whatever
# permissions your app needs.
# See https://developers.facebook.com/docs/reference/api/permissions/
# for a full list of permissions
FACEBOOK_SCOPE = 'user_likes,user_photos,publish_actions'

unless ENV["FACEBOOK_APP_ID"] && ENV["FACEBOOK_SECRET"]
  abort("missing env vars: please set FACEBOOK_APP_ID and FACEBOOK_SECRET with your app credentials")
end

unless ENV["FS_ID"] && ENV["FS_SECRET"]
  abort("missing env vars: please set FS_ID and FS_SECRET with your app credentials")
end

before do
  # HTTPS redirect
  if settings.environment == :production && request.scheme != 'https'
    redirect "https://#{request.env['HTTP_HOST']}"
  end
end

helpers do
  def host
    request.env['HTTP_HOST']
  end

  def scheme
    request.scheme
  end

  def url_no_scheme(path = '')
    "//#{host}#{path}"
  end

  def url(path = '')
    "#{scheme}://#{host}#{path}"
  end

  def authenticator
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
  end

  # allow for javascript authentication
  def access_token_from_cookie
    authenticator.get_user_info_from_cookies(request.cookies)['access_token']
  rescue => err
    warn err.message
  end

  def access_token
    session[:access_token] || access_token_from_cookie
  end

  def hit_object_to_cache(object)

    url = URI.parse('https://developers.facebook.com/tools/debug/og/object')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new(url.request_uri)
    req.set_form_data({"q" => object})
    http.request(req)
  end

end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  session[:access_token] = nil
  redirect "/auth/facebook"
end

get "/" do
  # Get base API Connection
  @graph  = Koala::Facebook::API.new(access_token)

  # Get public details of current application
  @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])

  if access_token
    @user    = @graph.get_object("me")
    @friends = @graph.get_connections('me', 'friends')
    @photos  = @graph.get_connections('me', 'photos')
    @likes   = @graph.get_connections('me', 'likes').first(4)

    # for other data you can always run fql
    @friends_using_app = @graph.fql_query("SELECT uid, name, is_app_user, pic_square FROM user WHERE uid in (SELECT uid2 FROM friend WHERE uid1 = me()) AND is_app_user = 1")
  end
  erb :index
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

# used to close the browser window opened to post to wall/send to friends
get "/close" do
  "<body onload='window.close();'/>"
end

# Doesn't actually sign out permanently, but good for testing
get "/preview/logged_out" do
  session[:access_token] = nil
  request.cookies.keys.each { |key, value| response.set_cookie(key, '') }
  redirect '/'
end

# define object places to retrieve data from foursquare
get "/object/:location_id" do
  client = Foursquare2::Client.new(:client_id => ENV['FS_ID'], :client_secret => ENV['FS_SECRET'])

  @location = client.venue(params[:location_id]); #this is the Matteo cafe for now. will be changed
  
  erb :location
end

# get "/postObject" do
#   client = Foursquare2::Client.new(:client_id => ENV['FS_ID'], :client_secret => ENV['FS_SECRET'])

#   @location = client.venue("4b65b46ff964a520acfa2ae3"); #this is the Matteo cafe for now. will be changed

#   @graph  = Koala::Facebook::API.new(access_token)
#   # @graph.put_connections("me", "feed", :message => "HelloWorld") this is working
#   @response = @graph.put_object("me", "headtoapp:location", :object =>
#     '{ app_id: 479332218823511,' +
#     'type: "headtoapp:venue",' +
#     'url: "https://head-to.herokuapp.com/object",'+
#     'title: ' + @location.name + ','+
#     'image: ' + @location.name + ','+
#     'location: { latitude: "'+@location.location.lat.to_s+'", longitude:"'+ @location.location.lng.to_s+'" },'+
#     'description: ' + @location.name + '}'
#   )
#   # @response = @graph.put_connections("me", "objects/headtoapp:location", :object=>"https://head-to.herokuapp.com/object")
#   erb :index

# end

get "/postAction/:location_id" do

  begin
    # hit_object_to_cache(object_url)
    # client = Foursquare2::Client.new(:client_id => ENV['FS_ID'], :client_secret => ENV['FS_SECRET'])

    # @location = client.venue(params[:location_id])
    # @response_obj = @graph.put_connections("me", "objects/headtoapp:venue", 
    #   :object => '{ "app_id": "479332218823511",' +
    #     '"type": "headtoapp:venue",' +
    #     '"url": "'+ object_url + '",'+
    #     '"title": "' + @location.name + '",'+
    #     '"image": "' + @location.photos.groups[1].items[0].url + '",'+
    #     '"description": "' + @location.name + '"}')
    @graph  = Koala::Facebook::API.new(access_token)
    object_url = "https://head-to.herokuapp.com/object/"+params[:location_id]
    response = @graph.put_connections("me", "headtoapp:head_to", 
      :venue => object_url,
      :end_time => (Time.now + 2*3600).iso8601 )
    redirect "/"
  rescue => @e
    erb :exception
  end
end

# Allows for direct oauth authentication
get "/auth/facebook" do
  session[:access_token] = nil
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
  session[:access_token] = authenticator.get_access_token(params[:code])
  redirect '/'
end
