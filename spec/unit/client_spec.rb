require 'spec_helper'
require 'jekyll'
require 'active_support/inflector'

describe Jekyll::Contentful::Client do

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    @base = File.join(__dir__, '../dummy')
    @site = Jekyll::Contentful::Client.scaffold(@base)
    @client = Jekyll::Contentful::Client.new(site: @site)
  end

  it 'should return content_types, sans-exclusions' do
    VCR.use_cassette 'contentful/types-excluded' do
      @site.config['contentful'] = { exclude: 'products' }
      types = @client.content_types
      expect(types.keys).to include('testable')
      expect(types.keys).to include('widget')
      expect(types.keys).to_not include('products')
    end
  end


  it 'should scaffold Jekyll site' do
    expect(@site).to be_instance_of(Jekyll::Site)
  end


  it 'should return collections glob' do
    @site.collections['articles'].read
    glob = @client.send(:collections_glob, 'articles')
    expect(glob).to include(@site.collections['articles'].first.path)
  end

  it 'should remove a collection, file by file' do
    @site.instance_variable_set('@collections_path', File.join(File.expand_path(@site.config['source']), 'tmp', 'collections'))
    file = File.join(@site.collections_path, '_testables', 'this-is-a-test.md')
    FileUtils.mkdir_p File.dirname(file)
    FileUtils.touch file
    expect(File.exists?(file)).to be_truthy
    @client.rm('testables')
    expect(File.exists?(file)).to be_falsey
  end

  it 'should return docs' do
    VCR.use_cassette 'contentful/types' do
      types = @client.content_types
    end
    VCR.use_cassette 'contentful/entries/testables' do
      docs = @client.docs
      expect(docs.dig('testables')).to be_a(Array)
      expect(docs.dig('testables').first).to be_a(Jekyll::Contentful::Document)
    end
  end

  it 'should return the CF delivery client' do
    expect(@client.client).to be_a(Contentful::Client)
  end

  it 'should return the CF management client' do
    expect(@client.management).to be_a(Contentful::Management::Client)
  end

end