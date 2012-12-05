#Windsor

####Windsor is a Ruby gem for [Ruby on Rails](http://rubyonrails.org/) that can help you build [RESTful](http://en.wikipedia.org/wiki/Representational_state_transfer) APIs more easily.  

##It provides:

* Better handling of HTTP methods and better use of HTTP status codes and headers
* Better support for [hyperlinks in representations](http://roy.gbiv.com/untangled/2008/rest-apis-must-be-hypertext-driven), making it easier to create some [standard links](http://www.iana.org/assignments/link-relations/link-relations.xml) as well as some links that are generated from your model relationships.
* Better support for collections of resources with built-in features like [AtomPub-style pagination](http://tools.ietf.org/html/rfc5005#section-3) and query parameter filtering.

##Current state:  
Under heavy development! This gem is currently very tied to ActiveModel for creating APIs, but we're working on decoupling that slightly so that Windsor controllers are more generally applicable and extendable.

##Install:
```ruby
gem install windsor
```
with Bundler:
```ruby
gem 'windsor'    
```
##Usage:

If you have a 'User' model, you can expose it as a RESTful resource by simply creating a controller that inherits from the Windsor controller and has the same name as the model:
```ruby
class UsersController < WindsorController
end
```
The controller extracts the model name from the controller name, and you can route to it like you normally would:
```ruby
scope :path => '/api' do
  resources :users
end
```
You get a bunch of default implementations of actions:
GET /api/users  will return a collection of users
POST /api/users will allow you to add a user to that collection   
GET /api/user/{id} will return a particular user with a matching id
DELETE /api/user/{id} will allow you to delete that user with the matching id
PUT /api/user/{id} will allow you to delete that user with the matching id

Here's how a GET to /api/users/1 would look:
```javascript
{
  "username" : "greggg",
  "email_address" : "greggg@example.com",
  "links" : {
    "self" : { "href" : "http://example.com/api/users/1" },
    "index" : { "href" : "http://example.com/api/users" }
  }
}
```
Here's how a GET to /api/users/ (the collection) would look:
```javascript
{
  "users" : [
    {
      "username" : "greggg",
      "email_address" : "greggg@example.com",
      "links" : {
        "self" : { "href" : "http://example.com/api/users/1" }
      }
    },
    {
      "username" : "samdec",
      "email_address" : "samdec@example.com",
      "links" : {
        "self" : { "href" : "http://example.com/api/users/2" }
      }
    },
    {
      "username" : "seth",
      "email_address" : "seth@example.com",
      "links" : {
        "self" : { "href" : "http://example.com/api/users/3" }
      }
    }
  ],
  "links" : {
    "self" : { "href" : "http://example.com/api/users" }
  },
  "pagination" : {
    "total_items" : 9,
    "max_page_size" : 3,
    "links" : {
      "next" : { "href" : "http://example.com/api/users?page=2" },
      "first" : { "href" : "http://example.com/api/users?page=1" },
      "last" : { "href" : "http://example.com/api/users?page=3" }
    }
  }
}
```

What if we don't want to allow an action (like DELETE for example)?
```ruby
class UsersController < WindsorController
  def set_actions
    actions :all, :except => [:destroy]  # allow all actions, except destroy
  end
end
```
If you have a model that is a child of another model simply set up your nested routes:
```ruby
scope :path => '/api' do
  resources :accounts do
    resources :users
  end
end
```
then in your Users controller:
```ruby
class UsersController < WindsorController
  def view_scope
    { :account_id => params[:account_id] }
  end

  def create_scope
    { :account_id => params[:account_id] }
  end
end
```
to get hypermedia links between your account and user:
```ruby
class UsersController < WindsorController
  def to_representation(object)
    object["links"]["account"] = 
      { "href" => url_for(:controller => "accounts", :action => "show", :id => params[:account_id] ) } 
  end
end

class AccountsController < WindsorController
  def to_representation(object)
    object["links"]["users"] = { "href" => url_for(:controller => "users", :action => "index") }
  end
end
```
What if we also don't want to show some of the attributes that are on the model (like created_at, updated_at, and id for example)?
```ruby 
class UsersController < WindsorController
  def set_actions
    actions :all, :except => [:destroy]  # allow all actions, except destroy
  end
	
  def set_attributes
    attributes :all, :except => [:created_at, :updated_at, :id]  #show all attributes, except created_at, updated_at, and id
  end
end
```
Windsor allows you to override any of its methods in order to achieve what you need. ```view_scope```, ```create_scope```, and ```to_representation``` are there to be overridden to support customizing your resource, but you can also override things like ```model_class``` and ```get_controller_name``` in case you want your controller name to be different than your model name.

```view_scope ``` returns a hash that gets passed into the ActiveRecord query. Modify this to create a default filter when viewing items (collections are filtered automatically by query parameters, though you can use ```view_scope``` to add more filters). ```create_scope``` is the same except its added to the creation of an object.

```to_representation``` is the last place your representation goes before being rendered. The entire representation is passed in (as a hash) and here you can add or subtract any fields you want.

If you want to have a model name that is different than the controller name, for example a User model, but an AdminUsers controller, you need to override two methods in the AdminUsers controller: ```model_class``` and ```get_controller_name```. Just make ```model_class``` return ```User``` and ```get_controller_name``` return ```"AdminUsers"```.

If need be you can also override any of the controller actions and build your own custom action while still retaining some of the error handling and helper methods from Windsor.

This is currently really only useful if you have a single model, or a subset of a model, that you want to expose for basic CRUD with a RESTful interface without much extra processing logic, but that need arises quite often. The ultimate goal of Windsor is to allow you to easily define resources indepedent of your models, be able to perform CRUD on those resources, and link your resources together, with as little boilerplate as possible.


