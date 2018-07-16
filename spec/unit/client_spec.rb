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

  it 'should return collections' do
    expect(@client.send(:collections)).to match_array(%w[articles podcasts messages series trailers])
  end

  it 'should return only collections specified in options' do
    @client.options = {
      "collections" => ['trailers']
    }
    expect(@client.send(:collections)).to match_array(%w[trailers])
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
    expect(@client.send(:get_entries_of_type, 'articles').collect(&:data))
      .to eq(Jekyll::Contentful::Client.entries[:article].to_a)
  end

  it 'should return collections glob' do
    @site.collections['articles'].read
    glob = @client.send(:collections_glob, 'articles')
    expect(glob).to include(@site.collections['articles'].first.path)
  end

  context 'get_entries_of_type()' do
    cassette 'contentful/articles'

    it 'should return document instances for each CF entry' do
      documents = @client.send(:get_entries_of_type, 'articles')
      expect(documents.all?{|d| d.class.name == 'Jekyll::Contentful::Document' }).to be(true)
    end
  end

  context 'fetch_entries()' do
    it 'fetches all entries when there are more than 1000' do
      VCR.use_cassette 'contentful/messages' do
        documents = @client.class.send(:fetch_entries, 'message')
        expect(documents.size).to eq(1068)
      end
    end

    it 'fetches fewer entries when a limit is specified' do
      VCR.use_cassette 'contentful/messages-limit' do
        documents = @client.class.send(:fetch_entries, 'message', limit: 3)
        expect(documents.size).to eq(3)
      end
    end
  end

  it 'should build belongs_to references for any has_many relationship' do
    VCR.use_cassette 'contentful/documents' do
      @client.options = { 'collections' => %w(series messages), 'limit' => 100 }
      @client.add_belongs_to_for_every_has_many!
    end

    docs = @client.send(:documents)
    series = docs.detect{|doc| doc.frontmatter.dig('content_type') == 'series' && doc.frontmatter.dig('id') == '3vfkg7rU3KYkQCcOOiUWuq' }
    message = docs.detect{|doc| doc.frontmatter.dig('content_type') == 'message' && doc.frontmatter.dig('id') == 'i5ec6JNJGSAsGaECu2yOY' }

    expect(message.frontmatter.dig('series')).to include(series.frontmatter.dig('id'))
  end
end