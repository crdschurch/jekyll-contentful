require 'spec_helper'
require 'jekyll'
require 'active_support/inflector'

describe Jekyll::Contentful::Client do

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    base = File.join(__dir__, '../dummy')
    @site = Jekyll::Contentful::Client.scaffold(base)
    @client = Jekyll::Contentful::Client.new(site: @site)
    VCR.use_cassette('contentful/articles') do
      @doc = @client.send(:get_entries, 'articles').first
    end
  end

  it 'should return the collection name' do
    expect(@doc.send(:collection_name)).to eq('articles')
  end

  it 'should return filename' do
    expect(@doc.send(:filename)).to match(/collections\/_articles\/[^\.]*\.md/)
  end

  it 'should return frontmatter' do
    yml = @doc.send(:frontmatter)
    expect(yml).to be_instance_of(Hash)
    %w(layout title image author topic date slug).each do |k|
      expect(yml.keys).to include(k)
    end
  end

  it 'should write the file' do
    @doc.dir = File.join(@doc.dir, 'tmp')
    @doc.filename = 'testing.md'
    path = @doc.send(:path)
    FileUtils.rm(path) if File.exist?(path)
    @doc.write!
    expect(File.exist?(path)).to be(true)
  end

end