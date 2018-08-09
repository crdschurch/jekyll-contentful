require 'spec_helper'
require 'pry'
require 'jekyll'
require 'active_support/inflector'

describe Jekyll::Contentful::Document do

  let(:product) {
    VCR.use_cassette('contentful/entries/products') do
      @client.docs.dig('products').detect{|p| p.data.id == '5im4abQIPKgSE0CUey4uYY' }
    end
  }

  let(:article) {
    VCR.use_cassette('contentful/entries/articles') do
      @client.docs.dig('articles').detect{|a| a.data.id == '4swni4tAHme0gI8yySC6Sy' }
    end
  }

  let(:author) {
    VCR.use_cassette('contentful/entries/authors') do
      @client.docs.dig('authors').first
    end
  }

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    base = File.join(__dir__, '../dummy')
    @site = Jekyll::Contentful::Client.scaffold(base)
    @client = Jekyll::Contentful::Client.new(site: @site)
  end

  it 'should return the collection name' do
    expect(product.send(:collection_name)).to eq('products')
  end

  it 'should return filename' do
    expect(product.send(:filename)).to match(/collections\/_products\/[^\.]*\.md/)
  end

  it 'should return parse liquid template for filenames, where required' do
    stamp = DateTime.parse(article.data.published_at).strftime('%Y-%m-%d')
    expect(article.filename).to eq("collections/_articles/#{stamp}-#{article.data.slug}.md")
  end

  it 'should return slug if defined' do
    allow(product.data).to receive(:slug).and_return('lorem-ipsum')
    expect(product.send(:slug)).to eq('lorem-ipsum')
  end

  # TODO ... review the implementation and/or need for "links" following refactor
  it 'should add links to frontmatter' do
    pending
    expect(product.send(:frontmatter_links)).to eq({})
  end

  it 'should return frontmatter entry mappings' do
    product.schema.dig('fields').each do |field|
      expect(product.data.send(field)).to_not be_nil
    end
  end

  it 'should expose entry id in frontmatter of every document' do
    yml = product.send(:frontmatter)
    expect(yml.keys).to include('id')
    expect(yml.keys).to include('content_type')
  end

  it 'should return "content-type and id" if slug is not defined' do
    allow(product.data).to receive(:title).and_return('this is a test')
    allow(product.data).to receive(:slug) { raise }
    expect(product.send(:slug)).to eq("#{product.data.content_type.id}-#{product.data.id}")
  end

  it 'should return frontmatter' do
    yml = product.send(:frontmatter)
    expect(yml).to be_instance_of(Hash)
  end

  it 'should write the file' do
    path = write_document!(product)
    expect(File.exist?(path)).to be(true)
  end

  context 'mapping fields from Contentful' do

    it 'should populate has-many references' do
      expect(article.frontmatter.dig('widgets')).to be_a(Array)
    end

    it 'should populate all fields for references' do
      %w(full_name id content_type).each do |field_name|
        frontmatter = article.frontmatter
        expect(frontmatter.dig('author').keys).to include(field_name)
        expect(frontmatter.dig('author', field_name)).to_not be_nil
      end
    end

    it 'should not throw an error if body is nil' do
      allow(product.data).to receive('body').and_return(nil)
      expect{ write_document!(product) }.to_not raise_error
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