module Jekyll
  module Contentful
    class Document

      attr_accessor :data, :schema, :cfg, :ct_cfg, :filename, :dir, :body, :frontmatter

      def initialize(obj, schema:, cfg:, ct_cfg:)
        @data = obj
        @cfg = cfg
        @ct_cfg = ct_cfg || {}
        @schema = schema
        @dir = FileUtils.pwd
        reload!
      end

      def write!
        unless is_future? || is_unpublished?
          FileUtils.mkdir_p File.dirname(path)
          File.open(path, 'w') do |file|
            file.write "#{@frontmatter.to_yaml}---\n\n#{body}"
          end
        end
      end

      def reload!
        @filename = parse_filename
        @frontmatter = build_frontmatter
      end

      def self.process_associations!(data)
        data.each do |content_type, docs|
          next unless docs.present? && docs.first.ct_cfg.dig('belongs_to').present?
          docs.each do |doc|
            doc.ct_cfg.dig('belongs_to').each do |type, attr|
              attr_name = type
              type = type.pluralize if data[type].nil?
              type = type.singularize if data[type].nil?
              next unless data[type]
              doc.frontmatter[attr_name] = data[type].detect { |d|
                next unless d.frontmatter[attr]
                d.frontmatter[attr].collect { |f| f['id'] }.include?(doc.data.id)
              }.try(:frontmatter)
            end
          end
        end
      end

      private

        def body
          if content_key.present?
            @data.fields[content_key]
          end
        end

        def content_key
          if !cfg.nil? && cfg.keys.include?('content')
            cfg.dig('content').intern
          elsif @data.fields.keys.include?(:body)
            :body
          end
        end

        def is_future?
          if @frontmatter['published_at'] #not all content has this field
            @frontmatter['published_at'] > Time.now
          end
        end

        def is_unpublished?
          if @frontmatter['unpublished_at'] #not all content has this field
            @frontmatter['unpublished_at'] <= Time.now
          end
        end

        def build_frontmatter
          @frontmatter ||= begin
            defaults = {
              'id' => data.id,
              'contentful_id' => data.id,
              'content_type' => data.content_type.id
            }
            ct_fields = data.fields.stringify_keys

            # Remove content field (e.g. body) from ct_fields object
            if ct_fields.keys.include?(content_key.to_s)
              ct_fields.except!(content_key.to_s)
            end

            mapped_fields = (ct_cfg.dig('map') || {}).map { |k, v| [k, parse_field(v, ct_fields[v])] }.to_h
            fields = ct_fields.map { |k, v| [k, parse_field(k, v)] }.to_h
            defaults.merge(fields).merge(mapped_fields)
          end
        end

        def parse_field(field_name, value)
          if value.is_a? ::Contentful::Asset
            parse_asset(value)
          elsif value.is_a? ::Contentful::Link
            nil
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
            "url" => asset.fields.dig(:file).url,
            "id" => asset.id
          }
        end

        def parse_reference(entry, field_name)
          if entry.is_a?(String) or entry.is_a?(Hash)
            entry
          else
            fields = @schema.dig('references', field_name.to_s) || []
            if fields.all?{|f| f.is_a?(String) }
              parse_entry_fields(entry, fields)
            elsif entry.type == 'Asset'
              fields = ['url']
              parse_entry_fields(entry, fields)
            else
              fields = fields.reduce({}, :merge)[entry.content_type.id]
              parse_entry_fields(entry, fields)
            end
          end
        end

        def parse_entry_fields(entry, fields)
          fields = (fields || []) + ['id']
          fields.push 'content_type' unless entry.class.name.include?('Asset')

          fields.uniq.collect{|field_name|
            if field_name == 'content_type'
              value = entry.send(:content_type).id
            else
              value = parse_field(field_name, entry.send(field_name)) rescue nil
            end
            next if value.nil?

            Hash[
              field_name,
              parse_field(field_name, value)
            ]
          }.compact.reduce({}, :merge)
        end

        def parse_filename
          _f = slug
          if (@cfg || {}).keys.include?("filename")
            _f = render_liquid(@cfg.dig('filename'))
          end
          ['collections', "_#{collection_name}", "#{_f}.md"].join('/')
        end

        def render_liquid(tpl)
          template = Liquid::Template.parse(tpl) # Parses and compiles the template
          tpl_vars = template.root.nodelist.select{|obj| obj.class.name == 'Liquid::Variable' }

          mapped = tpl_vars.collect do |obj|
            value = @data.fields.send(obj.name.name.to_sym) rescue nil
            value = value.id if value.is_a? ::Contentful::Link
            Hash[*obj.name.name, value]
          end.reject(&:blank?).reduce({}, :merge)
          template.render mapped.merge(data.fields.stringify_keys)
        end

        def slug
          @data.slug
        rescue
          "#{@data.content_type.id}-#{@data.id}"
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
