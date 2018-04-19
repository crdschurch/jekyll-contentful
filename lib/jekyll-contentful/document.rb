require 'jekyll'
require 'kramdown'
require 'active_support/inflector'

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
          body = "#{frontmatter.to_yaml}---\n\n"
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
            if v.is_a?(Array) && v.size == 2 && @data.fields.keys.include?(v.first.to_sym)
              matter[k] = @data.send(v.first.to_sym).collect { |obj| obj.send(v.last.to_sym) }
              next
            end
            if @data.fields.keys.include?(v.to_sym)
              matter[k] = @data.send(v.to_sym)
              next
            end
            if v.split('/').size > 1 && @data.fields.keys.include?(v.split('/').first.to_sym)
              matter[k] = @data
              v.split('/').each { |attr| matter[k] = matter[k].respond_to?(attr) ? matter[k].send(attr) : nil }
            end
          end
          matter
        end

        def filename
          _f = begin
            @data.slug
          rescue
            @data.title.parameterize
          end

          if @options.keys.include?("filename")
            @template = Liquid::Template.parse(@options['filename']) # Parses and compiles the template
            tpl_vars = @template.root.nodelist.select{|obj| obj.class.name == 'Liquid::Variable' }
            mapped = tpl_vars.collect{|obj| Hash[*obj.name.name, @data.send(obj.name.name.to_sym)] }.reduce({}, :merge)
            _f = @template.render(mapped)
          end

          ['collections', "_#{collection_name}", "#{_f}.md"].join('/')
        end

        def collection_name
          @options.dig('collection_name').to_s
        end

    end
  end
end