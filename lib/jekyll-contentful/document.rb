require 'pry'
require 'jekyll'
require 'kramdown'
require 'active_support/inflector'

module Jekyll
  module Contentful
    class Document

      attr_accessor :data, :schema, :cfg, :filename, :dir, :body, :frontmatter, :associations

      def initialize(obj, schema:, cfg:)
        @data = obj
        @cfg = cfg
        @schema = schema
        @dir = FileUtils.pwd
        reload!
      end

      def write!
        FileUtils.mkdir_p File.dirname(path)
        File.open(path, 'w') do |file|
          @body = "#{@frontmatter.to_yaml}---\n\n"
          file.write @body
        end
        Jekyll.logger.info "#{filename} imported"
      end

      def association_ids
        @associations.keys.collect{|key| @frontmatter.dig(key) }.flatten
      end

      def reload!
        @filename = parse_filename
        # @associations = frontmatter_associations
        @frontmatter = build_frontmatter
      end

      private

        def build_frontmatter
          @frontmatter ||= begin
            defaults = {
              "id" => @data.id,
              "content_type" => @data.content_type.id
            }
            Hash[@data.fields.collect do |field_name, value|
              [
                field_name.to_s,
                parse_field(field_name, value)
              ]
            end].merge(defaults)
          end
        end

        def parse_field(field_name, value)
          if value.is_a? ::Contentful::Asset
            parse_asset(value)
          elsif value.is_a? Array
            value.collect do |entry|
              parse_reference(entry, field_name)
            end
          elsif value.is_a? ::Contentful::Entry
            parse_reference(value, field_name)
          else
            value
          end
        end

        def parse_asset(asset)
          {
            "url" => asset.fields.dig(:file).url
          }
        end

        def parse_reference(entry, field_name)
          fields = @schema.dig('references', field_name.to_s)
          if fields.all?{|f| f.is_a?(String) }
            parse_entry_fields(entry, fields)
          else
            fields = fields.reduce({}, :merge)[entry.content_type.id]
            parse_entry_fields(entry, fields)
          end
        end

        def parse_entry_fields(entry, fields)
          (fields + ['id']).uniq.collect{|field_name|
            value = entry.send(field_name) rescue nil
            Hash[
              field_name,
              parse_field(field_name, value)
            ]
          }.reduce({}, :merge)
        end

        # def build_frontmatter
        #   matter = {
        #     "id" => data.id,
        #     "content_type" => @data.content_type.id
        #   }
        #   matter.merge!(frontmatter_links)
        #   frontmatter_entry_mappings.each do |k, v|
        #     if v.match(/\{{2}/)
        #       matter[k] = render_liquid(v)
        #       next
        #     end
        #     if @data.fields.keys.include?(v.to_sym)
        #       matter[k] = @data.send(v.to_sym)
        #       next
        #     end
        #     if v.split('/').size > 1 && @data.fields.keys.include?(v.split('/').first.to_sym)
        #       matter[k] = @data
        #       v.split('/').each do |attr|
        #         if matter[k].is_a?(Array)
        #           matter[k] = matter[k].map { |x| x.send(attr) }
        #         else
        #           matter[k] = matter[k].respond_to?(attr) ? matter[k].send(attr) : nil
        #         end
        #       end
        #     end
        #   end
        #   matter
        # end

        # def frontmatter_associations
        #   if @options.keys.include?('has_many')
        #     has_many = (@options.dig('has_many') || {}).keys
        #     yml = has_many.collect do |assoc|
        #       [assoc, "#{assoc}/id"]
        #     end
        #     Hash[yml]
        #   else
        #     {}
        #   end
        # end

        # def frontmatter_links
        #   return {} unless @options.dig('links')
        #   links = {}
        #   @options.dig('links').each do |key, cfg|
        #     entry = (Client.entries[cfg['content_type'].to_sym] || [])
        #       .select { |e| e.send(cfg['field']).collect(&:id).include?(@data.id) rescue false }.first
        #     next if entry.nil?
        #     links[key] = entry.send(cfg['value'])
        #   end
        #   links
        # end

        # def frontmatter_entry_mappings
        #   (@options.dig('frontmatter') || {}).merge(frontmatter_associations)
        # end

        def parse_filename
          _f = slug
          if @cfg.keys.include?("filename")
            _f = render_liquid(@cfg.dig('filename'))
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
          @data.sys.dig(:content_type).id.pluralize
        end

    end
  end
end
