require 'simplecov'
SimpleCov.start 'rails'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
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
  body = { :error => { :type => type, :message => message } }
  unless detail.empty?
    body[:error][:detail] = detail
  end
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