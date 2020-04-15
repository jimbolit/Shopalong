require 'sinatra'
require 'haml'
require 'sass'
require 'compass'

configure do
  Compass.configuration do |config|
    config.project_path = File.dirname(styles_scss.scss)
    config.sass_dir = 'public'
  end

  set :haml, format: :html5
  set :sass, Compass.sass_engine_options
  set :scss, Compass.sass_engine_options
end

get '/sass.css' do
  sass :sass_file
end

get '/scss.css' do
  scss :scss_file
end