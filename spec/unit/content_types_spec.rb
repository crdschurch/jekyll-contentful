require 'spec_helper'
require 'jekyll'
require 'active_support/inflector'

describe Jekyll::Contentful::ContentTypes do

  before do
    @klass = Jekyll::Contentful::ContentTypes
  end

  it 'should return the CF space instance' do
    VCR.use_cassette 'contentful/space' do
      expect(@klass.send(:space)).to be_a(Contentful::Management::Space)
    end
  end

  it 'should return the management client' do
    expect(@klass.send(:management)).to be_a(Contentful::Management::Client)
  end

  it 'should load Jekyll config file' do
    path = File.expand_path(__dir__), '../dummy'
    cfg = @klass.send(:load_jekyll_config, path)
    expect(cfg).to be_a(Object)
    expect(cfg.keys).to include('exclude')
  end

  it 'should return all entries from Contentful' do
    path = File.expand_path(__dir__), '../dummy'
    VCR.use_cassette 'contentful/types' do
      content_types = @klass.all(path)
      %w(testable product article author widget).each do |type|
        expect(content_types.keys).to include(type)
      end
      article = content_types['article']
      expect(article.dig('fields')).to match_array(['title', 'published_at', 'slug'])
      expect(article.dig('references', 'author')).to match_array([{"author"=>["full_name"]}])
      expect(article.dig('references', 'widgets')).to match_array([{"widget"=>["title"]}, {"testable"=>["title"]} ])
    end
  end

  it 'should return fields & references for a content_type' do
    model = nil
    VCR.use_cassette 'contentful/types' do
      model = @klass.send(:get_models).detect{|m| m.id == 'article' }
    end
    refs = @klass.send(:get_fields, model)
    expect(refs).to be_a(OpenStruct)
    expect(refs.fields).to be_a(Array)
    expect(refs.fields.all?{|f| f.is_a?(Contentful::Management::Field) }).to be true
    expect(refs.references).to be_a(Array)
    expect(refs.references.all?{|f| f.is_a?(Contentful::Management::Field) }).to be true
  end

  it 'should get all models from Contentful' do
    VCR.use_cassette 'contentful/types' do
      models = @klass.send(:get_models)
      expect(models).to be_a(Contentful::Management::Array)
    end
  end

  it 'should return schema, sans excluded content-types' do
    VCR.use_cassette 'contentful/types' do
      allow(@klass).to receive(:config).and_return({ 'exclude' => ['testable', 'widget'] })
      schema = @klass.send(:get_schema)
      keys = schema.collect(&:first)
      expect(keys).to match_array(['product','article','author'])
      expect(keys).to_not include('testable')
      expect(keys).to_not include('widget')
    end
  end

  it 'should parse and return field references via block' do
    VCR.use_cassette 'contentful/types' do
      models = @klass.send(:get_models)
      model = models.detect{|m| m.id == 'article' }
      fields = @klass.send(:get_fields, model)
      references = fields.references.collect(&@klass.send(:parse_reference_field))
      expect(references).to match_array([{"author"=>["author"]}, {"widgets"=>["testable", "widget"]}])
    end
  end

  context 'with --collections' do

    # before do
      # @klass.instance_variable_set('@options', { 'collections' => @types })
    # end

    it 'should return content_types defined' do
      types = ['products', 'article']
      path = File.expand_path(__dir__), '../dummy'
      options = { 'collections' => types }
      VCR.use_cassette 'contentful/types-filtered' do
        expect(@klass.send(:all, path, options).keys).to match_array(types.collect(&:singularize))
      end
    end

  end

end