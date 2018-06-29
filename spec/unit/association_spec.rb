require 'spec_helper'
require 'jekyll'

describe Jekyll::Contentful::Associations do

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    base = File.join(__dir__, '../dummy')
    @site = ::Jekyll::Contentful::Client.scaffold(base)
    @site.read
    @assoc = ::Jekyll::Contentful::Associations.new(@site)
  end

  it 'should get content_types that declare associations' do
    expect(@assoc.types.keys).to eql(['series'])
  end

  it 'should concat disparate collections into a single array' do
    expect(@assoc.send(:get_docs_of_type, ['trailers', 'messages']).length).to eq(2)
  end

  context 'run!()' do

    it 'should populate associations on document objects' do
      @assoc.run!
      doc = @site.collections['series'].docs.first
      expect(doc.data.keys).to include('associations')
      expect(doc.data['associations']).to_not be_empty
    end

  end

end
