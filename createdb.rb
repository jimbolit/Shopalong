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
  String :address
end
DB.create_table! :products do
  primary_key :id
  foreign_key :category_id
  String :name
  String :amount
  String :image
  Decimal :price
end
DB.create_table! :orders do
  primary_key :id
  foreign_key :user_id
  String  :address
  Timestamp :timestamp
end
DB.create_table! :orders_products do
  primary_key :id
  foreign_key :order_id
  foreign_key :product_id
end
DB.create_table! :categories do
  primary_key :id
  String :name
  String :image
end


# Insert initial (seed) data
lists_table = DB.from(:lists)
users_table = DB.from(:users)
products_table = DB.from(:products)
categories_table = DB.from(:categories)

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
                    mobile_number: "+642102377971",
                    address: "6 Westbourne Road, Remuera, Auckland, New Zealand",
                    password: BCrypt::Password.create("jim")
                    )

users_table.insert(name: "Jacinda Ardern", 
                    email: "jacinda@parliament.com",
                    mobile_number: "+61419763177",
                    address: "Molesworth Street, Pipitea, Wellington 6011",
                    password: BCrypt::Password.create("jacinda")
                    )

products_table.insert(name: "Meadow Fresh Uht Milk Standard Long Life 1L", 
                    amount: "1L",
                    image: "mf_uht_std_1l.jpg",
                    price: 2.89,
                    category_id: 1
                    )

products_table.insert(name: "Sanitarium Weetbix Wheat Biscuits", 
                    amount: "1.2Kg",
                    image: "weetbix12kg.jpg",
                    price: 7.60,
                    category_id: 1
                    )

products_table.insert(name: "Sanitarium Skippy Cornflakes", 
                    amount: "1L",
                    image: "skippycornflakes500g.jpg",
                    price: 4.30,
                    category_id: 1
                    )

products_table.insert(name: "Golden Crumpets Rounds 300g", 
                    amount: "300g",
                    image: "goldencrumpets.jpg",
                    price: 2.20,
                    category_id: 1
                    )

products_table.insert(name: "Sanitarium Marmite Yeast Spread", 
                    amount: "500g",
                    image: "marmite500.jpg",
                    price: 7.29,
                    category_id: 1
                    )

products_table.insert(name: "Kelloggs Nutrigrain Cereal
Volume 805g", 
                    amount: "805g",
                    image: "nutrigrain805.jpg",
                    price: 10.00,
                    category_id: 1
                    )

products_table.insert(name: "Frenz Free Range Eggs Dozen Mixed Grade", 
                    amount: "12pk",
                    image: "frenzmed12.jpg",
                    price: 8.99,
                    category_id: 1
                    )

products_table.insert(name: "Molenberg Toast Bread Original", 
                    amount: "700g",
                    image: "Molenberg-Toast-Bread-Original.jpg",
                    price: 3.40,
                    category_id: 2
                    )

products_table.insert(name: "Best Foods Mayonnaise Real 405g", 
                    amount: "405g",
                    image: "best-foods-mayonnase-405.jpg",
                    price: 5.00,
                    category_id: 2
                    )

products_table.insert(name: "San Remo Pasta Spaghetti pkt", 
                    amount: "500g",
                    image: "san-remo-spaghetti.jpg",
                    price: 3.99,
                    category_id: 3
                    )

products_table.insert(name: "Wattie's Pasta Sauce Traditional Garlic", 
                    amount: "420g",
                    image: "watties-tomato-sauce-garlic.jpg",
                    price: 2.50,
                    category_id: 3
                    )

products_table.insert(name: "Olivani Olive Oil Pure 1l", 
                    amount: "1L",
                    image: "olivani-olive-oil.jpg",
                    price: 13.00,
                    category_id: 4
                    )

products_table.insert(name: "Cerebos Salt Iodised Table Drum 300g", 
                    amount: "300g",
                    image: "cerebos-salt.jpg",
                    price: 1.69,
                    category_id: 4
                    )

products_table.insert(name: "Quilton Toilet Paper 18pk White Unscented", 
                    amount: "18pk",
                    image: "quilton-toilet-paper-18.jpg",
                    price: 10.99,
                    category_id: 5
                    )

products_table.insert(name: "Handee Paper Towels White 2pk", 
                    amount: "2pk",
                    image: "handee-paper-towels.jpg",
                    price: 3.50,
                    category_id: 5
                    )


categories_table.insert(
                        name: "Breakfast",
                        image: "breakfast.jpg"
                    )

categories_table.insert(name: "Lunch",
                        image: "lunchsam.jpg"
                    )
 
categories_table.insert(name: "Dinner Ingredients",
                        image: "dinner.jpg"
                    )

categories_table.insert(name: "Kitchen Essentials",
                        image: "essentials.jpg"
                    )

categories_table.insert(name: "Non-Food",
                        image: "toiletpaper.jpg"
                    )
 
categories_table.insert(name: "Pharmacy",
                        image: "pharmacy.jpg"
                    )
 
 

 



