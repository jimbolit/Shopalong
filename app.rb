require "sinatra"                                                               
require "sinatra/reloader" if development?                                      
require "sequel"                                                                
require "logger"                                                                
require "twilio-ruby"                                                           
require "bcrypt"   
require "geocoder"                                                             
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                        
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                    
def view(template); erb template.to_sym; end                                    
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'     
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }       
after { puts; }                                                                 
#######################################################################################

lists_table = DB.from(:purchases)
users_table = DB.from(:users)

# Twilio API credentials and connection
    account_sid = ENV["twilio_sid"]
    auth_token = ENV["twilio_token"]
    client = Twilio::REST::Client.new(account_sid, auth_token)

# Code starts

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end


get "/" do
    @lists = lists_table.all.to_a
    view "ists"
end

post "/lists/thanks" do
        
    lists_table.insert(user_id: session["user_id"],
                           items: params["items"],
                           date_posted: params["date_posted"],
                           comments:params["comments"],
                           delivery_location: params["delivery_location"])
    view "lists_thanks"
end

get "/list/:id" do
    @list = purchases_list.where(id: params["id"]).to_a[0]
    @users_table = users_table

    @location = @purchase[:delivery_location]
    @results = Geocoder.search("#{@location}")
    lat_long = @results.first.coordinates
    lat = lat_long[0]
    long = lat_long[1]
    @coords = "#{lat},#{long}"

    view "list"
end

 
# send the SMS from your trial Twilio number to your verified non-Twilio number 
    client.messages.create(
    from: "+12076186686", 
    to: "+642102377971",
    body: "Thanks for joining the #{@purchase[:title]} bandwagon. This text confirms that you are on the bandwagon!"
    )
  
    view "bandwagon_thanks"
end

get "/users/new" do
     view "new_user"
end

post "/users/create" do
    puts params
    hashed_password = BCrypt::Password.create(params["password"])
    users_table.insert(name: params["name"], email: params["email"], mobile_number: params["mobile_number"],password: hashed_password, mobile_number: params["mobile_number"])
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    user = users_table.where(email: params["email"]).to_a[0]
    puts BCrypt::Password::new(user[:password])
    if user && BCrypt::Password::new(user[:password]) == params["password"]
        session["user_id"] = user[:id]
        @current_user = user
        view "create_login"
    else
        view "create_login_failed"
    end
end

get "/logout" do
    session["user_id"] = nil
    @current_user = nil
    view "logout"
end
