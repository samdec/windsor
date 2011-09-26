#Windsor

####Windsor is a Ruby gem for [Ruby on Rails](http://rubyonrails.org/) that can help you build [RESTful](http://en.wikipedia.org/wiki/Representational_state_transfer) APIs more easily.  

##It provides:

* Better handling of HTTP methods and better use HTTP status codes and headers
* Better support for [hyperlinks in representations](http://roy.gbiv.com/untangled/2008/rest-apis-must-be-hypertext-driven), making it easier to create some [standard links](http://www.iana.org/assignments/link-relations/link-relations.xml) as well as some links that are generated from your model relationships.
* Better support for collections of resources with built-in features like [AtomPub-style pagination](http://tools.ietf.org/html/rfc5005#section-3).

##Current state:  
Under heavy development!  This gem is current very tied to ActiveModel for creating APIs, but we're working on decoupling that slightly so that Windsor controllers are more generally applicable and extendable.

Example:

If you have a 'User' model, you can expose it as a RESTful resource by simply creating a controller that inherits from the Windsor controller and has the same name as the model:

    class JsonResources::UsersController < JsonResourcesController
    end

The controller extracts the model name from the controller name, and you can route to it like you normally would:

    HelloREST::Application.routes.draw do
      namespace :json_resources, :path => '/api' do
        resources :users
      end
    end

You get a bunch of default implementations of actions:
GET /api/users  will return a collection of users
POST /api/users will allow you to add a user to that collection   
GET /api/user/{id} will return a particular user with a matching id
DELETE /api/user/{id} will allow you to delete that user with the matching id
PUT /api/user/{id} will allow you to delete that user with the matching id

Here's how a GET to /api/users/1 would look:

    {"username":"grizzle","email_address":"grizzle@example.com","self":"http://example.com/api/users/1","index":"http://example.com/api/users"},

Here's how a GET to /api/users/ (the collection) would look:

    {
     "users":[
      {"username":"asdf","email_address":"asdf@example.com","self":"http://example.com/api/users/1","index":"http://example.com/api/users"},
      {"username":"gdizzle","email_address":"gdizzle@example.com","self":"http://example.com/api/users/2","index":"http://example.com/api/users"},
      {"username":"samdec","email_address":"samdec@example.com","self":"http://example.com/api/users/3","index":"http://example.com/api/users"}
     ],
     "self":"http://example.com/api/users"
    }


What if we don't want to allow an action (like DELETE for example)?

    class JsonResources::UsersController < JsonResourcesController
      def set_actions
        actions :all, :except => [:destroy]  # allow all actions, except destroy
      end
    end

What if we also don't want to show some of the attributes that are on the model (like created_at, updated_at, and id for example)?
 
    class JsonResources::UsersController < JsonResourcesController
      def set_actions
        actions :all, :except => [:destroy]  # allow all actions, except destroy
      end
      
      def set_attributes
        attributes :all, :except => [:created_at, :updated_at, :id]  #show all attributes, except created_at, updated_at, and id
      end
    end

This is currently really only useful if you have a single model that you want to expose for basic CRUD with a RESTful interface without much extra processing logic, but we find that we have that need quite often.  We're hoping that this can expand to be even more general purpose though.  Only JSON is supported at this time, but we will probably support XML as well in the future.

