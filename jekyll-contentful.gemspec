lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-contentful/version'

Gem::Specification.new do |s|
  s.name        = 'jekyll-contentful'
  s.version     = Jekyll::Contentful::VERSION
  s.licenses    = ['BSD-3']
  s.summary     = "Jekyll integration for Contentful"
  s.authors     = ["Ample"]
  s.email       = 'taylor@helloample.com'
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_paths = ["lib"]
  s.add_dependency 'jekyll'
  s.add_dependency 'contentful', '>= 2.6.0'
  s.add_dependency 'contentful-management', '~> 2.6'
  s.add_dependency 'dotenv'
  s.add_dependency 'activesupport'
end