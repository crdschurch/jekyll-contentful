require 'rspec'
require 'bundler/setup'
Bundler.setup
require 'jekyll-contentful'
require 'vcr'
require 'timecop'
require 'pry'

Dir['./spec/support/**/*.rb'].each { |f| require f }

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr"
  config.hook_into :webmock
  config.filter_sensitive_data('<CONTENTFUL_MANAGEMENT_TOKEN>') { ENV['CONTENTFUL_MANAGEMENT_TOKEN'] }
  config.filter_sensitive_data('<CONTENTFUL_ACCESS_TOKEN>') { ENV['CONTENTFUL_ACCESS_TOKEN'] }
end

RSpec.configure do |config|
  # config.extend CassetteHelper
end