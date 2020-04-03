require "sinatra"                                                               
require "sinatra/reloader" if development?                                      
require "sequel"                                                                
require "logger"                                                                
require "twilio-ruby"                                                           
require "bcrypt"   
require "geocoder" 
require "google_places"  

connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                        
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                    
def view(template); erb template.to_sym; end                                    
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'     
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }       
after { puts; }                                                                 
#######################################################################################

lists_table = DB.from(:lists)
users_table = DB.from(:users)
products_table = DB.from(:products)

# Twilio API credentials and connection
    account_sid = ENV["twilio_sid"]
    auth_token = ENV["twilio_token"]
    client = Twilio::REST::Client.new(account_sid, auth_token)

# Code starts

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    view "welcome"
end

get "/categories" do
    view "categories"
end

get "/breakfast" do
    @breakfasts = products_table.where(category: "breakfast").to_a
    view "breakfast"
end

post '/basket' do
  content_type :json
  session[:basket] ||= []
  session[:basket] << params[:product_id]
  session[:basket].to_json
end

get '/basket' do
    puts session[:basket]
    puts "hello"
    begin
     @test = session[:basket]
     @products = products_table.where(id: session[:basket]).to_a
    
    end
    view "basket"
end

get '/test' do
    view "test"
end



get "/lists" do
    @lists = lists_table.all.to_a
    view "lists"
end

post "/lists/thanks" do
        
    lists_table.insert(user_id: session["user_id"],
                           items: params["items"],
                           date_posted: params["date_posted"],
                           comments:params["comments"],
                           delivery_location: params["delivery_location"])

# send SMS from trial Twilio number to my verified non-Twilio number 
            client.messages.create(
            from: "+12076186686", 
            to: "+642102377971",
            body: "Thanks for making your list to be delivered to #{params["delivery_location"]} , we will be in touch soon with an expected delivery time"
            )

            view "list_new"
end

get "/list/:id" do
    @list = lists_table.where(id: params["id"]).to_a[0]
    @users_table = users_table

    @location = @list[:delivery_location]
    @results = Geocoder.search("#{@location}")
    lat_long = @results.first.coordinates
    lat = lat_long[0]
    long = lat_long[1]
    @coords = "#{lat},#{long}"

    view "list"
end

get "/users/new" do
     view "new_user"
end

post "/users/create" do
    puts params
    hashed_password = BCrypt::Password.create(params["password"])
    users_table.insert(name: params["name"], 
    email: params["email"], 
    mobile_number: params["mobile_number"],
    address: params["address"],
    password: hashed_password)
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
