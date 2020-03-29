# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :lists do
  primary_key :id
  foreign_key :user_id
  String :date_posted
  String :comments, text: true
  String :items, text:true
  String :delivery_location
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
  String :mobile_number
end
DB.create_table! :products do
  primary_key :id
  String :name
  String :amount
  String :category 
  String :image
  Numeric :price
end


# Insert initial (seed) data
lists_table = DB.from(:lists)
users_table = DB.from(:users)
products_table = DB.from(:products)

lists_table.insert( 
                    date_posted: "March 25 2020",
                    comments: "Please call once you are out the front",
                    delivery_location: "111 Puka Crescent, Matarangi, New Zealand",
                    items: "2x Fly spray <br/>
                            Two litre bottle of dark blue milk <br/>
                            1kg bag of plain flour <br/>
                            2x large blocks of black forest chocolate <br/>
                            1kg block of Edam cheese <br/>
                            Bag of ground plunger coffee",
                    user_id: 1)

lists_table.insert(
                    date_posted: "March 26 2020",
                    comments: "Big house with the green fence",
                    delivery_location: "6 Westbourne Rd, Remuera, Auckland, New Zealand",
                    items: "2x 6 pack of two ply toilet paper <br/>
                            1l bottle of pulp orange juice <br/>
                            spf 50 sunscreen 200 ml",
                    user_id: 1)

users_table.insert(name: "Jim Little", 
                    email: "jameslittle@outlook.co.nz",
                    mobile_number: "02102377971",
                    password: BCrypt::Password.create("jim")
                    )

users_table.insert(name: "Xindi Zhang", 
                    email: "xindi.k.zhang@gmail.com",
                    mobile_number: "+61419763177",
                    password: BCrypt::Password.create("xindi")
                    )

products_table.insert(name: "Meadow Fresh Uht Milk Standard Long Life 1L", 
                    amount: "1L",
                    category: "Breakfast",
                    image: "mf_uht_std_1l.jpg",
                    price: 2.89
                    )