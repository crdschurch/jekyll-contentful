require 'spec_helper'

describe Jekyll::Contentful::Document do

  let(:product) {
    VCR.use_cassette('contentful/entries/products') do
      @client.sync!.dig('products').detect{|p| p.data.id == '5im4abQIPKgSE0CUey4uYY' }
    end
  }

  let(:widget) {
    VCR.use_cassette('contentful/entries/widgets') do
      @client.sync!.dig('widgets').detect{|p| p.data.id == '3o97VNLQgvCwxMQlSWL40S' }
    end
  }

  let(:article) {
    VCR.use_cassette('contentful/entries/articles') do
      @client.sync!.dig('articles').detect{|a| a.data.id == '4swni4tAHme0gI8yySC6Sy' }
    end
  }

  let(:author) {
    VCR.use_cassette('contentful/entries/authors') do
      @client.sync!.dig('authors').first
    end
  }

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    base = File.join(__dir__, '../dummy')
    @site = Jekyll::Contentful::Client.scaffold(base)
    @client = Jekyll::Contentful::Client.new(site: @site)
  end

  it 'should evaluate published_at frontmatter' do
    product.frontmatter['published_at'] = nil
    expect(product.send(:is_future?)).to be(nil)
    product.frontmatter['published_at'] = Time.now - 6000
    expect(product.send(:is_future?)).to be(false)
    product.frontmatter['published_at'] = Time.now + 6000
    expect(product.send(:is_future?)).to be(true)
  end

  it 'should evaluate unpublished_at frontmatter' do
    product.frontmatter['unpublished_at'] = nil
    expect(product.send(:is_unpublished?)).to be(nil)
    product.frontmatter['unpublished_at'] = Time.now - 6000
    expect(product.send(:is_unpublished?)).to be(true)
    product.frontmatter['unpublished_at'] = Time.now + 6000
    expect(product.send(:is_unpublished?)).to be(false)
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

  it 'should return frontmatter entry mappings' do
    product.schema.dig('fields').each do |field|
      expect(product.data.send(field)).to_not be_nil
    end
  end

  it 'should expose entry id in frontmatter of every document' do
    yml = product.send(:frontmatter)
    expect(yml.keys).to include('id')
    expect(yml.keys).to include('contentful_id')
    expect(yml.keys).to include('content_type')
  end

  it 'should not expose body in frontmatter' do
    yml = product.send(:frontmatter)
    expect(yml.keys).to_not include('body')
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

  it 'should exclude content field from frontmatter' do
    product.cfg = { "content" => "title" }
    product.remove_instance_variable('@frontmatter')
    yml = product.send(:build_frontmatter)
    expect(yml.keys).to_not include("title")
  end

  it 'should return key for the "content" field (e.g. body)' do
    product.data.fields[:body] = "Ever thus to deadbeats, Lebowski"
    expect(product.send(:content_key)).to be(:body)

    product.remove_instance_variable('@data')
    product.cfg = { "content" => "title" }
    expect(product.send(:content_key)).to be(:title)
  end

  it 'should write the file' do
    path = write_document!(product)
    expect(File.exist?(path)).to be(true)
  end

  it 'should render Liquid templates against document frontmatter when generating filename' do
    article.data.fields[:some_date_value] = '2018-08-01T00:00-04:00'
    article.cfg['filename'] = "{{ some_date_value | date: '%d%Y%m' }}-testing"
    expect(article.send(:parse_filename)).to eq('collections/_articles/01201808-testing.md')
  end

  it 'should include body content in written file if it exists' do
    content = 'This is body content'
    product.data.fields[:body] = content
    path = write_document!(product)
    expect(File.read(path).gsub(/\A---(.|\n)*?---\n\n/,'')).to eq(content)
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

    it 'should populate file content with body attribute, if one exists' do
      content = 'This is body content'
      product.data.fields[:body] = content
      expect(product.send(:body)).to eq(content)
    end

    it 'should populate file content with specified attribute where one exists' do
      expect(@site.config.dig('collections', 'articles', 'content')).to eq('body')
      content = 'This is body content'
      article.data.fields[:body] = content
      expect(article.send(:body)).to eq(content)
    end

    it 'should map fields to custom keys' do
      expect(article.frontmatter.keys).to include('name')
      expect(article.frontmatter['name']).to eq(article.frontmatter['title'])
    end

    it 'should map belongs_to reciprocal fields' do
      expect(widget.frontmatter.keys).to include('article')
      expect(widget.frontmatter.dig('article', 'title')).to eq('Something Else')
    end

    it 'accepts JSON objects as fields' do
      exp_json = [
        {"minutes" => 12, "seconds" => 34, "description" => "Test #1"},
        {"minutes" => 2, "seconds" => 4, "description" => "Test #2"}
      ]
      expect(widget.frontmatter['custom_json']).to eq(exp_json)
    end

    it 'writes JSON as accepted YAML frontmatter' do
      exp_text = "custom_json:\n- minutes: 12\n  seconds: 34\n  description: 'Test #1'\n- minutes: 2\n  seconds: 4\n  description: 'Test #2'\n"
      expect(File.read(widget.send(:path))).to include(exp_text)
    end

  end

  def write_document!(obj, date=Time.now, filename='testing.md')
    obj.dir = File.join(obj.dir, 'tmp')
    obj.frontmatter['date'] = date
    obj.filename = filename
    path = obj.send(:path)
    FileUtils.rm(path) if File.exist?(path)
    obj.write!
    path
  end

end
