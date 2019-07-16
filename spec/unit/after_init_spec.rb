require 'spec_helper'

RSpec.describe 'after init hook' do

  before do
    ENV['CONTENT_TYPE'] = 'widget'
    Jekyll.logger.adjust_verbosity(quiet: true)
    @base = File.join(__dir__, '../dummy')
    @site = Jekyll::Contentful::Client.scaffold(@base)
    Jekyll::Hooks.trigger(@site, :after_init)
  end

  it 'should reflect environment variables in queries' do
    expect(@site.config.dig('contentful','widget','query')).to eq('content_type=widget')
  end

end
