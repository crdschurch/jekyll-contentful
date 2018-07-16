require 'pry'
require 'jekyll'
require 'kramdown'
require 'active_support/inflector'

module Jekyll
  module Contentful
    class Document

      attr_accessor :data, :options, :filename, :dir, :body, :frontmatter, :associations

      def initialize(obj, options={})
        @data = obj
        @options = options
        @dir = FileUtils.pwd
        reload!
      end

      def build
        body = "#{@frontmatter.to_yaml}---\n\n"
        unless @options.dig('body').nil?
          if @data.respond_to?(@options.dig('body').to_sym)
            content = @data.send(@options.dig('body').to_sym)
            body = "#{body}#{Kramdown::Document.new(content || '').to_html}"
          end
        end
        body
      end

      def write!
        FileUtils.mkdir_p File.dirname(path)
        File.open(path, 'w') do |file|
          @body = build
          file.write @body
        end
        Jekyll.logger.info "#{filename} imported"
      end

      def association_ids
        @associations.keys.collect{|key| @frontmatter.dig(key) }.flatten
      end

      def reload!
        @filename = parse_filename
        @associations = frontmatter_associations
        @frontmatter = build_frontmatter
      end

      private

        def build_frontmatter
          matter = {
            "id" => data.id,
            "content_type" => @data.content_type.id
          }
          matter.merge!(frontmatter_links)
          frontmatter_entry_mappings.each do |k, v|
            if v.match(/\{{2}/)
              matter[k] = render_liquid(v)
              next
            end
            if @data.fields.keys.include?(v.to_sym)
              matter[k] = @data.send(v.to_sym)
              next
            end
            if v.split('/').size > 1 && @data.fields.keys.include?(v.split('/').first.to_sym)
              matter[k] = @data
              v.split('/').each do |attr|
                if matter[k].is_a?(Array)
                  matter[k] = matter[k].map { |x| x.send(attr) }
                else
                  matter[k] = matter[k].respond_to?(attr) ? matter[k].send(attr) : nil
                end
              end
            end
          end
          matter
        end

        def frontmatter_associations
          if @options.keys.include?('has_many')
            yml = @options.dig('has_many').keys.collect do |assoc|
              [assoc, "#{assoc}/id"]
            end
            Hash[yml]
          else
            {}
          end
        end

        def frontmatter_links
          return {} unless @options.dig('links')
          links = {}
          @options.dig('links').each do |key, cfg|
            entry = (Client.entries[cfg['content_type'].to_sym] || [])
              .select { |e| e.send(cfg['field']).collect(&:id).include?(@data.id) rescue false }.first
            next if entry.nil?
            links[key] = entry.send(cfg['value'])
          end
          links
        end

        def frontmatter_entry_mappings
          (@options.dig('frontmatter') || {}).merge(frontmatter_associations)
        end

        def parse_filename
          _f = slug
          if @options.keys.include?("filename")
            _f = render_liquid(@options['filename'])
          end
          ['collections', "_#{collection_name}", "#{_f}.md"].join('/')
        end

        def render_liquid(tpl)
          template = Liquid::Template.parse(tpl) # Parses and compiles the template
          tpl_vars = template.root.nodelist.select{|obj| obj.class.name == 'Liquid::Variable' }
          mapped = tpl_vars.collect { |obj| Hash[*obj.name.name, @data.send(obj.name.name.to_sym)] rescue nil }.reject(&:blank?).reduce({}, :merge)
          template.render(mapped)
        end

        def slug
          @data.slug
        rescue
          @data.title.parameterize
        end

        def path
          File.join(@dir, @filename)
        end

        def collection_name
          @options.dig('collection_name').to_s
        end

    end
  end
end
