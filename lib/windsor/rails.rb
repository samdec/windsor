require 'rails'
require 'windsor'

module Windsor
  class Engine < Rails::Engine
    engine_name :windsor
    #paths.app.controllers = "app/controllers"
  end
end