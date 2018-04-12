require 'jekyll'
require 'kramdown'

module Jekyll
  module Contentful
    class Document

      attr_accessor :data, :options

      def initialize(obj, options={})
        @data = obj
        @options = options
        # binding.pry
      end

      def write!(force_rebuild=false)
        if ! File.exist?(filename) || force_rebuild
          FileUtils.mkdir_p "./#{File.dirname(filename)}"
          File.open(filename, 'w') do |file|
            body = "---\n#{frontmatter}\n---\n\n"
            unless @options.dig('body').nil?
              body = "#{body}#{Kramdown::Document.new( @data.send(@options.dig('body').to_sym) ).to_html}"
            end
            file.write body
          end
          Jekyll.logger.info "#{filename} imported"
        else
          Jekyll.logger.warn "#{filename} already exists"
        end
      rescue Exception => e
        binding.pry
      end

      private

        def frontmatter
          other_attrs = (@options.dig('frontmatter','other') || {}).collect do |k,v|
            "#{k}: #{v}"
          end
          mappings = (@options.dig('frontmatter','entry_mappings') || {}).collect do |k,v|
            "#{k}: #{@data.send(v.to_sym)}" if  @data.fields.keys.include?(v.to_sym)
          end
          (mappings.compact + other_attrs).join("\n")
        end

        def filename
          if @data.respond_to?(:published_date)
            slug = "#{DateTime.parse(@data.published_date).strftime('%Y-%m-%d')}-#{@data.slug}.md"
          else
            slug = @data.slug
          end
          ['collections', "_#{collection_name}", slug].join('/')
        end

        def collection_name
          @options.dig('collection_name').to_s
        end

    end
  end
end