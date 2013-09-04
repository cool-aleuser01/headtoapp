require "sinatra"
require 'koala'
require "foursquare2"

enable :sessions
set :raise_errors, false
set :show_exceptions, false

FACEBOOK_SCOPE = 'publish_actions'

unless ENV["FACEBOOK_APP_ID"] && ENV["FACEBOOK_SECRET"]
  abort("missing env vars: please set FACEBOOK_APP_ID and FACEBOOK_SECRET with your app credentials")
end

unless ENV["FS_ID"] && ENV["FS_SECRET"]
  abort("missing env vars: please set FS_ID and FS_SECRET with your app credentials")
end

#before do
#  # HTTPS redirect
#  if settings.environment == :production && request.scheme != 'https'
#    redirect "https://#{request.env['HTTP_HOST']}"
#  end
#end

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

end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  session[:access_token] = nil
  redirect "/auth/facebook"
end

get "/" do
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
  @location = client.venue(params[:location_id]); 
  
  erb :location
end

get "/postAction/:location_id" do
  begin
    @graph  = Koala::Facebook::API.new(access_token)
    object_url = "http://headtoapp.herokuapp.com/object/" + params[:location_id]
    response = @graph.put_connections("me", "headtoapp:head_to", 
      :venue => object_url,
      :expires_in => 4*60*60 )
      #:end_time => (Time.now + 2*3600).iso8601 )
    redirect "/"
  rescue => @e
    erb :exception
  end
end

get "/channel.html" do
  begin
    "<script src='//connect.facebook.net/en_US/all.js'></script>"  
  rescue  => e
    warn e.message
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
