require 'haml'
require 'sassc'
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
categories_table = DB.from( :categories)
orders_products_table = DB.from( :orders_products)
orders_table = DB.from( :orders)

# Twilio API credentials and connection
    account_sid = ENV["twilio_sid"]
    auth_token = ENV["twilio_token"]
    client = Twilio::REST::Client.new(account_sid, auth_token)

# SCSS compiling code

template = File.read('public/styles_scss.scss')
options = { style:               :compressed,
            filename:            'styles_scss.scss',
            output_path:         'styles_scss.css',
            source_map_file:     'styles_scss.css.map',
            load_paths:          ['styles'],
            source_map_contents: true }
engine = SassC::Engine.new(template, options)
css = engine.render
File.write('public/styles_scss.css', css)
map = engine.source_map
File.write('public/styles_scss.css.map', map)


    # Code starts

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end


get "/" do
    view "welcome"
end

get "/categories" do
    @categories = categories_table.to_a
    view "categories"
end

get "/category/:id" do
    @products = products_table.where(category_id: params[ :id]).to_a

   @basket = session[:basket].select{|x| x[:order_quantity]>0}
     basket_ids = @basket.map {|x| x.values[0]}
     
     @basket_products = products_table.where(id: basket_ids).to_a
    
     @sub_total = 0
     @basket_products.each{
         |i| @sub_total = @sub_total + i[:price] * @basket.find{
             |y| y[:product_id] == i[:id]
             }[:order_quantity]
     }

    view "products"
end

get "/breakfast" do
    @products = products_table.where(category: "breakfast").to_a
    view "products"
end


post '/basket' do
  content_type :json
  session[:basket] ||= []
  session[:basket].delete_if {|h| h[:product_id] == params[:product_id].to_i} 
  session[:basket] << {:product_id => params[:product_id].to_i, :order_quantity => params[:order_quantity].to_i}
  session[:basket].to_json
end

get '/basket' do
    begin
     @basket = session[:basket].select{|x| x[:order_quantity]>0}
     basket_ids = @basket.map {|x| x.values[0]}
     
     @products = products_table.where(id: basket_ids).to_a
    
     @sub_total = 0
     @products.each{
         |i| @sub_total = @sub_total + i[:price] * @basket.find{
             |y| y[:product_id] == i[:id]
             }[:order_quantity]
     }
    end
     if @basket == []
        view "basket_empty"
     else
        view "basket"  
     end
end

get '/delivery-details' do
    begin
     @basket = session[:basket].select{|x| x[:order_quantity]>0}
     basket_ids = @basket.map {|x| x.values[0]}
     
     @products = products_table.where(id: basket_ids).to_a
    
     @sub_total = 0
     @products.each{
         |i| @sub_total = @sub_total + i[:price] * @basket.find{
             |y| y[:product_id] == i[:id]
             }[:order_quantity]
     }
    end  
    view "delivery_details"
end


post '/payment' do
    begin
     
    session[:address] = params[:address]
    session[:first_name] = params[:first_name]
    session[:last_name] = params[:last_name]
    session[:email] = params[:email]
    session[:phone_number] = params[:phone_number]

         @basket = session[:basket].select{|x| x[:order_quantity]>0}
     basket_ids = @basket.map {|x| x.values[0]}
     
     @products = products_table.where(id: basket_ids).to_a
    
     @sub_total = 0
     @products.each{
         |i| @sub_total = @sub_total + i[:price] * @basket.find{
             |y| y[:product_id] == i[:id]
             }[:order_quantity]
     }
    end  
    session[:total] = @sub_total
    view "payment"
end

get '/delivery-confirmation' do
    begin
        begin
            # need to link up order_id
            current_order = orders_table.insert( user_id: 1,
                                address: session[:address],
                                first_name: session[:first_name],
                                last_name: session[:last_name],
                                email: session[:email],
                                phone_number: session[:phone_number],
                                total: session[:total],
                                created_at: Time.now
                                )

            @current_order_details = orders_table.where(id: current_order).to_a
        end
        @basket = session[:basket]
        for products in @basket
            orders_products_table.insert(order_id: @current_order_details[0][:id],
                            product_id: products[:product_id],
                            order_quantity: products[:order_quantity])
        end
    end
    @basket = []
    session[:basket]=[]
    session[:address]=[]
    session[:first_name]=[]
    session[:last_name]=[]
    session[:email]=[]
    session[:phone_number]=[]
    view "delivery_confirmation"

    # next step is to enable adding and subtracting items
end

get '/test' do
    erb :test, :layout => false
end



get "/lists" do
    @orders = orders_table.all.to_a
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
    @list = orders_table.where(id: params["id"]).to_a[0]
    @items = orders_products_table.where(order_id: @list[:id]).to_a
    @products = products_table
    @categories = categories_table


    @users_table = users_table

    @location = @list[:address]
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