require 'rails'

require_relative '../app/controllers/windsor_controller'

require 'simplecov'
SimpleCov.start 'rails'

require 'rubygems'
require 'bundler/setup'
require 'windsor'

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
  
RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
end

def json_post_response_should_be(action, input, expected, code)
  post_json(action, input)
  response_should_be(expected, code)
end

def response_should_be(expected, code)
  response.body.should == expected.to_json
  response.status.should == code
end

def error_response_should_be(code, type, message = "", detail = {})
  body = { :error => { :type => type, :message => message, :detail => detail } }
  response_should_be(body, code)
end

def post_json(action, body)
  set_json_headers_and_body(body)
  post action
end

def put_json(action, id, body)
  set_json_headers_and_body(body)
  put action, :id => id
end

def set_json_headers_and_body(body)
  request.env['RAW_POST_DATA'] = body.to_json
  request.env["HTTP_ACCEPT"] = "application/json"
  request.env["CONTENT_TYPE"] = "application/json"
end