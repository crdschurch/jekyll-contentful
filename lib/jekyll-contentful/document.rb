require 'jekyll'
require 'kramdown'

module Jekyll
  module Contentful
    class Document

      attr_accessor :data, :options

      def initialize(obj, options={})
        @data = obj
        @options = options
      end

      def write!
        FileUtils.mkdir_p "./#{File.dirname(filename)}"
        File.open(filename, 'w') do |file|
          body = "#{frontmatter}---\n\n"
          unless @options.dig('body').nil?
            body = "#{body}#{Kramdown::Document.new( @data.send(@options.dig('body').to_sym) ).to_html}"
          end
          file.write body
        end
        Jekyll.logger.info "#{filename} imported"
      end

      private

        def frontmatter
          matter = @options.dig('frontmatter','other') || {}
          (@options.dig('frontmatter','entry_mappings') || {}).each do |k, v|
            if @data.fields.keys.include?(v.to_sym)
              matter[k] = @data.send(v.to_sym)
              next
            end
            if v.split('/').size > 1 && @data.fields.keys.include?(v.split('/').first.to_sym)
              matter[k] = @data
              v.split('/').each { |attr| matter[k] = matter[k].send(attr) }
            end
          end
          matter.to_yaml
        end

        def filename
          if @data.respond_to?(:published_date)
            slug = "#{DateTime.parse(@data.published_date).strftime('%Y-%m-%d')}-#{@data.slug}.md"
          else
            slug = "#{@data.slug}.md"
          end
          ['collections', "_#{collection_name}", slug].join('/')
        end

        def collection_name
          @options.dig('collection_name').to_s
        end

    end
  end
end