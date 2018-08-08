require 'rspec'
require 'bundler/setup'
Bundler.setup
require 'jekyll-contentful'
require 'vcr'

Dir['./spec/support/**/*.rb'].each { |f| require f }

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr"
  config.hook_into :webmock
end

RSpec.configure do |config|
  # config.extend CassetteHelper
end