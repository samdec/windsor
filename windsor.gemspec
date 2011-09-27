$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "windsor/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "windsor"
  s.version     = Windsor::VERSION
  s.authors     = ["Sam DeCesare", "Gregg Caines"]
  s.email       = ["sam@samdecesare.com", "gregg@caines.ca"]
  s.homepage    = "http://windsorapi.org"
  s.summary     = "Windsor is a plugin for building RESTful APIs in Rails."
  s.description     = "Windsor is a plugin for building RESTful APIs in Rails."

  s.files = Dir["{app,lib}/**/*"] + ["LICENSE", "Rakefile", "README.rdoc"]
  # s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.1.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
end
