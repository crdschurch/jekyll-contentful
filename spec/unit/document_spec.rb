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

  it 'should return slug if defined' do
    allow(@doc.data).to receive(:slug).and_return('lorem-ipsum')
    expect(@doc.send(:slug)).to eq('lorem-ipsum')
  end

  it 'should return frontmatter extras' do
    cfg = @site.config.dig('contentful', 'content_types', 'articles', 'frontmatter', 'other')
    cfg.each do |mapped,src|
      expect(@doc.send(:frontmatter_extras)[mapped]).to eq(src)
    end
  end

  it 'should return frontmatter entry mappings' do
    cfg = @site.config.dig('contentful', 'content_types', 'articles', 'frontmatter', 'entry_mappings')
    cfg.each do |mapped,src|
      expect(@doc.send(:frontmatter_entry_mappings)[mapped]).to eq(src)
    end
  end

  it 'should return parameterized title if slug is not defined' do
    allow(@doc.data).to receive(:title).and_return('this is a test')
    allow(@doc.data).to receive(:slug) { raise }
    expect(@doc.send(:slug)).to eq('this-is-a-test')
  end

  it 'should return frontmatter' do
    yml = @doc.send(:frontmatter)
    expect(yml).to be_instance_of(Hash)
    %w(layout title image author topic date slug).each do |k|
      expect(yml.keys).to include(k)
    end
  end

  it 'should write the file' do
    path = write_document!
    expect(File.exist?(path)).to be(true)
  end

  context 'mapping fields from Contentful' do

    it 'should support arrays of exactly two items' do
      pending "My brain hurts."
      raise
    end

    it 'should support individual fields' do
      title = 'Ever thus to deadbeats, Lebowski'
      allow(@doc.data).to receive(:title).and_return(title)
      expect(@doc.send(:frontmatter)['title']).to eq(title)
    end

    it 'should support nested attributes' do
      mappings = @doc.send(:frontmatter_entry_mappings)
      allow(mappings).to receive(:author).and_return('author/full_name')
      author_name = 'Walter Sobchak'
      allow(@doc.data.author).to receive(:full_name).and_return(author_name)
      expect(@doc.send(:frontmatter)['author']).to be(author_name)
    end

    it 'should not raise exception if mapped field doesn\'t actually exist in CF payload' do
      allow(@doc).to receive(:frontmatter_entry_mappings).and_return({ "foo" => "bar" })
      expect{ @doc.send(:frontmatter) }.to_not raise_error
    end

    it 'should not throw an error if body is nil' do
      allow(@doc.data).to receive('body').and_return(nil)
      expect{ write_document! }.to_not raise_error
    end

  end

  def write_document!(filename='testing.md')
    @doc.dir = File.join(@doc.dir, 'tmp')
    @doc.filename = filename
    path = @doc.send(:path)
    FileUtils.rm(path) if File.exist?(path)
    @doc.write!
    path
  end

end