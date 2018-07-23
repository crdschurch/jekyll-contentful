guard :rspec, cmd: "bundle exec rspec" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # Feel free to open issues for suggestions and improvements
  watch(/^lib\/jekyll-contentful\/(.+)\.rb$/) { | m | "spec/unit/#{m[1]}_spec.rb" }
  # watch(%r{^lib/(?<path>.+)\.rb$}) { |m| "spec/lib/#{m[:path]}_spec.rb" }

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)

end
