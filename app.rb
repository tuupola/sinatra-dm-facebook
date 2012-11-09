require "pp"

DataMapper::Logger.new($stdout, :debug)

configure :development do
  #DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/example.db")
  DataMapper.setup(:default, "mysql://example:example@mysql.example.com/example_sinatra")
end

configure :production do
  DataMapper.setup(:default, "mysql://example:example@localhost/example_sinatra")
end

require "models.rb" # Models
require "monkey.rb" # Monkeypatches

use Rack::Static, :urls => ["/css", "/js", "/img"], :root => "public"

enable :sessions
#use Rack::Flash, :accessorize => [:notice, :error, :success]

#use Rack::FunkyCache
use Rack::Facebook::MethodFix, :exclude => proc { |env| env['PATH_INFO'].match(/^\/submit/) }

set :haml,       :attr_wrapper => '"'

set :tab_url,    "https://www.facebook.com/xxx"
set :app_url,    "http://apps.facebook.com/sinatra-dm-facebook/"
set :canvas_url, "http://sinatra-dm-facebook.taevas.com/"
set :client_id,  "352323201529563" 
set :secret_id,  "ca095b0b8ca3418866e91f1a004724cf" 

# Disable Rack::Protection totally to avoid problems with Facebook.
disable :protection

before do
  pp "** params ************************************************************"
  pp params
  update_session_from_session if params["session"]
  update_session_from_signed_request if params["signed_request"] 
  @fb = FBGraph::Client.new(:client_id => settings.client_id,
                            :secret_id => settings.secret_id,
                            :token => session[:oauth_token])
  pp "** session ***********************************************************"
  pp session
  pp "** current_user_info *************************************************"
  pp current_user_info
  #pp "** FQL ***************************************************************"
  #pp @fb.fql.query("SELECT uid, name FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) and sex='female'")["data"]
end


before "/admin/*" do
  require_login!
end

get "/" do
  facebook_redirect settings.tab_url unless facebook_external_hit?
  "external hit?"
end

get "/install" do
  haml :install, :layout => false
end

get "/tab" do
  haml :tab, :layout => false
end

post "/submit" do
  if session[:user_id].nil?
    data = { :status => "fail" }
  else
    # Do stuff here
    data  = { :status => "ok" }
  end
  data.to_json
end

get "/channel" do
  haml :channel, :layout => false
end

post "/channel" do
  haml :channel, :layout => false
end


helpers do
  
  # Called when user has already authenticated and returns to app or the
  # page is reloaded.
  def update_session_from_signed_request
    response["P3P"] = 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"'    
    pp "** parsed signed_request **********************************************"
    pp data = FBGraph::Canvas.parse_signed_request(settings.secret_id, params["signed_request"])
    session[:user_id] = data["user_id"]
    session[:oauth_token] = data["oauth_token"] || params[:oauth_token] # Set from FB.Login
  end

  # Called after FB.ui({ method: "oauth" ... });
  def update_session_from_session
    response["P3P"] = 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"'
    pp "** parsed params[session] *********************************************"  
    pp data = JSON.parse(params["session"])
    session[:user_id] = data["uid"]
    session[:oauth_token] = exchange_sessions(data["session_key"])
  end
  
  def exchange_sessions(session_key)
    options = {
      :body => {
        :client_id => settings.client_id,
        :client_secret => settings.secret_id,
        :sessions => session_key
      }
    }
    data = HTTParty.post("https://graph.facebook.com/oauth/exchange_sessions", options)
    data[0]["access_token"]
  end
  
  def signed_request
    FBGraph::Canvas.parse_signed_request(settings.secret_id, params["signed_request"])
  end
  
  def current_user
    @user ||= User.first_or_create({ :uid  => current_user_uid })
    if @user.name.nil?
      @user.name = current_user_info["name"]
      @user.oauth_token = session["oauth_token"]
      @user.save
    end
    @user
  end

  def current_user_uid
    session[:user_id]
  end
  
  def current_user_is_fan?
    true == signed_request["page"]["liked"]
  end
  
  # TODO: This suxor.
  def current_user_info
    begin
      @info ||= @fb.selection.me.info!.data
    rescue
      false
    end
  end
  
  # TODO: This suxor since it causes call to graph API.
  def ensure_in_facebook
    if not current_user_info
      redirect_to_tab
    end
  end
  
  def facebook_redirect(url)
    url = settings.app_url + url unless url =~ /^http/
    halt "<script type=\"text/javascript\">top.location.href=\"#{url}\"</script>"
  end
  
  def facebook_external_hit?
    false == request.user_agent.match("facebookexternalhit").nil?
  end
    
  def redirect_to_tab
    facebook_redirect settings.tab_url
  end
  
  #def oauth_url(url)
  #  "http://graph.facebook.com/oauth/authorize?client_id=#{settings.client_id}&redirect_uri=#{url}"
  #end
    
  def oauth_url(url)
    "https://www.facebook.com/dialog/oauth/?" +
    "client_id=#{settings.client_id}" +
    "&redirect_uri=#{Rack::Utils.escape(url)}" 
    #"&scope=user_birthday"
  end

  
  def local_ip
    # turn off reverse DNS resolution temporarily
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  

    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
  
  def hostname
    Socket.gethostname
  end
  
  def require_login!
    unless authorized?
      response["WWW-Authenticate"] = %(Basic realm="Example Admin")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ["admin", "siikret"]
  end
    
end
