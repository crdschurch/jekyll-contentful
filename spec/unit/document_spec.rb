require 'spec_helper'
require 'pry'
require 'jekyll'
require 'active_support/inflector'

describe Jekyll::Contentful::Client do

  let(:article) {
    VCR.use_cassette('contentful/articles') do
      return @client.send(:get_entries, 'articles').first
    end
  }

  let(:podcast) {
    VCR.use_cassette('contentful/podcasts') do
      return @client.send(:get_entries, 'podcasts').select { |p| p.data.id == '5q50uJgqNUkqkMmaegK6M8' }.first
    end
  }

  let(:series) {
    VCR.use_cassette('contentful/series') do
      return @client.send(:get_entries, 'series').first
    end
  }

  let(:message) {
    VCR.use_cassette('contentful/messages') do
      return @client.send(:get_entries, 'messages').first
    end
  }

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    base = File.join(__dir__, '../dummy')
    @site = Jekyll::Contentful::Client.scaffold(base)
    @client = Jekyll::Contentful::Client.new(site: @site)
  end

  it 'should return the collection name' do
    expect(article.send(:collection_name)).to eq('articles')
  end

  it 'should return filename' do
    expect(article.send(:filename)).to match(/collections\/_articles\/[^\.]*\.md/)
  end

  it 'should return slug if defined' do
    allow(article.data).to receive(:slug).and_return('lorem-ipsum')
    expect(article.send(:slug)).to eq('lorem-ipsum')
  end

  it 'should return frontmatter extras' do
    cfg = @site.config.dig('contentful', 'content_types', 'articles', 'frontmatter', 'other')
    cfg.each do |mapped,src|
      expect(article.send(:frontmatter_extras)[mapped]).to eq(src)
    end
  end

  it 'should return frontmatter entry mappings' do
    cfg = @site.config.dig('contentful', 'content_types', 'articles', 'frontmatter', 'entry_mappings')
    cfg.each do |mapped,src|
      expect(article.send(:frontmatter_entry_mappings)[mapped]).to eq(src)
    end
  end

  it 'should return parameterized title if slug is not defined' do
    allow(article.data).to receive(:title).and_return('this is a test')
    allow(article.data).to receive(:slug) { raise }
    expect(article.send(:slug)).to eq('this-is-a-test')
  end

  it 'should return frontmatter' do
    yml = article.send(:frontmatter)
    expect(yml).to be_instance_of(Hash)
    %w(layout title image author topic date slug).each do |k|
      expect(yml.keys).to include(k)
    end
  end

  it 'should write the file' do
    path = write_document!(article)
    expect(File.exist?(path)).to be(true)
  end

  context 'mapping fields from Contentful' do
    it 'should capitalize the title with liquid templating' do
      frontmatter = {"title"=>"{{ title | capitalize }}",
        "image"=>"image/url",
        "author"=>"author/full_name",
        "topic"=>"category/title",
        "date"=>"published_at",
        "slug"=>"slug",
        "tags"=>"tags"}
      allow(article).to receive(:frontmatter_entry_mappings).and_return(frontmatter)
      allow(article.data).to receive(:title).and_return('liquid test')
      expect(article.send(:frontmatter)['title']).to eq('Liquid test')
    end

    it 'should map a many reference to an array of values' do
      mappings = podcast.send(:frontmatter_entry_mappings)
      allow(mappings).to receive(:authors).and_return('author/full_name')
      expect(podcast.data.author.class).to eq(Array)
      expect(podcast.send(:frontmatter)['authors']).to include(podcast.data.author.first.full_name)
    end

    it 'should support individual fields' do
      title = 'Ever thus to deadbeats, Lebowski'
      allow(article.data).to receive(:title).and_return(title)
      expect(article.send(:frontmatter)['title']).to eq(title)
    end

    it 'should support nested attributes' do
      mappings = article.send(:frontmatter_entry_mappings)
      allow(mappings).to receive(:author).and_return('author/full_name')
      author_name = 'Walter Sobchak'
      allow(article.data.author).to receive(:full_name).and_return(author_name)
      expect(article.send(:frontmatter)['author']).to be(author_name)
    end

    it 'should not raise exception if mapped field doesn\'t actually exist in CF payload' do
      allow(article).to receive(:frontmatter_entry_mappings).and_return({ "foo" => "bar" })
      expect{ article.send(:frontmatter) }.to_not raise_error
    end

    it 'should not throw an error if body is nil' do
      allow(article.data).to receive('body').and_return(nil)
      expect{ write_document!(article) }.to_not raise_error

      allow(podcast.data).to receive('description').and_return(nil)
      expect{ write_document!(podcast) }.to_not raise_error
    end

    it 'should not render properties if they are not returned from CF' do
      expect(article.send(:frontmatter).keys).to include('slug')
      article.data.fields.delete(:slug)
      expect(article.send(:frontmatter).keys).to_not include('slug')
    end

  end

  def write_document!(obj, filename='testing.md')
    obj.dir = File.join(obj.dir, 'tmp')
    obj.filename = filename
    path = obj.send(:path)
    FileUtils.rm(path) if File.exist?(path)
    obj.write!
    path
  end

end