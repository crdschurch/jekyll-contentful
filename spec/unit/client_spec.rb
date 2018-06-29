require 'spec_helper'
require 'jekyll'
require 'active_support/inflector'

describe Jekyll::Contentful::Client do
  cassette 'contentful/articles'

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    base = File.join(__dir__, '../dummy')
    @site = Jekyll::Contentful::Client.scaffold(base)
    @client = Jekyll::Contentful::Client.new(site: @site)
  end

  it 'should scaffold Jekyll site' do
    expect(@site).to be_instance_of(Jekyll::Site)
  end

  it 'should return content_types' do
    expect(@client.send(:content_types)).to match_array(%w[articles podcasts messages series])
  end

  it 'should return config' do
    expect(@client.send(:cfg, 'articles')).to be_instance_of(Hash)
  end

  it 'should return client object, stored on the class' do
    expect(@client.send(:client)).to be_instance_of(Contentful::Client)
    expect(@client.send(:client)).to eq(@client.class.send(:client))
  end

  it 'should store a reference to entries on the class' do
    expect(Jekyll::Contentful::Client.entries).to eq(nil)
    expect(@client.send(:get_entries, 'articles').collect(&:data))
      .to eq(Jekyll::Contentful::Client.entries[:article].to_a)
  end

  it 'should return collections glob' do
    @site.collections['articles'].read
    glob = @client.send(:collections_glob, 'articles')
    expect(glob).to include(@site.collections['articles'].first.path)
  end

  context 'get_entries()' do
    cassette 'contentful/articles'

    it 'should return document instances for each CF entry' do
      documents = @client.send(:get_entries, 'articles')
      expect(documents.all?{|d| d.class.name == 'Jekyll::Contentful::Document' }).to be(true)
    end
  end

end