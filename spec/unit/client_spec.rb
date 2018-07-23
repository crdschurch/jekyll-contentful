require 'spec_helper'
require 'jekyll'
require 'active_support/inflector'

describe Jekyll::Contentful::Client do

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    @base = File.join(__dir__, '../dummy')
  end

  context 'on init' do

    # it 'should select collections that include a contentful key' do
    #   @site = Jekyll::Contentful::Client.scaffold(@base)
    #   @site.config['collections'] = { "posts" => { "contentful" => true }, "widgets" => {} }
    #   @client = Jekyll::Contentful::Client.new(site: @site)
    #   expect(@client.models.keys).to include('posts')
    #   expect(@client.models.keys).to_not include('widgets')
    # end

  end

  context 'after init' do
    before do
      @site = Jekyll::Contentful::Client.scaffold(@base)
      VCR.use_cassette 'contentful/spaces' do
        @client = Jekyll::Contentful::Client.new(site: @site)
      end
    end

    context 'with mocked data' do
      # before do
      #   fake_content_types = {
      #     "testable" => {
      #       "fields" => ["title"],
      #       "references" => ["widgets", "product"]
      #     }
      #   }
      #   allow(@client).to receive(:content_types).and_return(fake_content_types)
      # end

      it 'should return Contentful client' do
        expect(@client.send(:client)).to be_instance_of(Contentful::Client)
      end

      it 'should return content types' do
        VCR.use_cassette 'contentful/content_types' do
          content_types = @client.content_types
          expect(content_types.dig('testable', 'references', 'widgets')).to match_array(content_types.dig('widget', 'fields'))
        end
      end

      it 'should sync documents' do
        VCR.use_cassette 'contentful/entries' do
          @client.sync!
          # TODO
        end
      end
    end

    it 'should get content_types' do
      VCR.use_cassette 'contentful/content_types' do
        content_types = @client.content_types
        expect(content_types.keys).to match_array(%w(testable widget product))
        expect(content_types.dig('testable').keys).to match_array(%w(fields references))
        expect(content_types.dig('testable', 'fields')).to match_array(%w(title))
        expect(content_types.dig('testable', 'references')).to match_array([{"widgets"=>["title"]}, {"product"=>["title"]}])
      end
    end
  end

=begin
  context 'loading articles' do
    cassette 'contentful/articles'

    it 'should scaffold Jekyll site' do
      expect(@site).to be_instance_of(Jekyll::Site)
    end

    it 'should return collections' do
      expect(@client.send(:collections)).to match_array(%w[articles authors podcasts messages series trailers])
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
      Jekyll::Contentful::Client.entries = nil
      expect(Jekyll::Contentful::Client.entries).to eq(nil)
      expect(@client.send(:get_entries_of_type, 'articles').collect(&:data))
        .to eq(Jekyll::Contentful::Client.entries[:article].to_a)
    end

    it 'should return collections glob' do
      @site.collections['articles'].read
      glob = @client.send(:collections_glob, 'articles')
      expect(glob).to include(@site.collections['articles'].first.path)
    end

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

  it 'should build links_to references for any model that has a belongs_to' do
    VCR.use_cassette 'contentful/documents' do
      @client.options = { 'collections' => %w(series messages), 'limit' => 100 }
        @client.add_belongs_to!
    end

    docs = @client.send(:documents)
    series = docs.detect{|doc| doc.frontmatter.dig('content_type') == 'series' && doc.frontmatter.dig('id') == '4iswJxw2BOUgC8asqoIc4o' }
    message = docs.detect{|doc| doc.frontmatter.dig('content_type') == 'message' && doc.frontmatter.dig('id') == '2Ya4RNjhpuku2eUy4mOyku' }

    expect(message.frontmatter.dig('links_to', 'series', 0, 'id')).to include(series.frontmatter.dig('id'))
  end

  it 'should normalize sort order for client queries' do
    load './lib/jekyll-contentful/client.rb'
    expect(@client.class.send(:sort_order, 'title desc')).to eq('-fields.title')
    expect(@client.class.send(:sort_order, 'sys.createdAt asc')).to eq('sys.createdAt')
  end
=end

end