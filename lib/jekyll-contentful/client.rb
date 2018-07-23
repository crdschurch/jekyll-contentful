require 'active_support/inflector'
require 'contentful/management'

module Jekyll
  module Contentful
    class Client

      class << self
        attr_accessor :entries

        def store_entries(type_id, limit, order)
          self.entries ||= {}
          self.entries[type_id.to_sym] = fetch_entries(type_id, limit: limit, order: order)
        end

        def scaffold(app_root)
          overrides = Jekyll::Configuration.new.read_config_file(File.join(app_root, '_config.yml'))
          site_config = Jekyll::Utils.deep_merge_hashes(Jekyll::Configuration::DEFAULTS, overrides.merge({
            "source" => app_root,
            "destination" => File.join(app_root, '_site')
          }))
          Jekyll::Site.new(site_config)
        end

        def sort_order(order)
          if order.nil?
            '-sys.createdAt'
          else
            field, dir = order.split(' ')
            if order[0..3] == 'sys.'
              "#{'-' if dir == 'desc'}#{field}"
            else
              "#{'-' if dir == 'desc'}fields.#{field}"
            end
          end
        end

        private

          def fetch_entries(type_id, limit: nil, entries: [], order: nil)
            this_page = client.entries({
              content_type: type_id,
              limit: (limit || 1000),
              skip: entries.size,
              order: sort_order(order)
            }).to_a
            entries.concat(this_page)

            if this_page.size == 1000
              fetch_entries(type_id, limit: limit, entries: entries, order: order)
            else
              entries
            end
          end

          def client
            @client ||= begin
              ::Contentful::Client.new(
                access_token: ENV['CONTENTFUL_ACCESS_TOKEN'],
                space: ENV['CONTENTFUL_SPACE_ID'],
                environment: (ENV['CONTENTFUL_ENV'] || 'master')
              )
            end
          end

          def management
            @management ||= begin
              ::Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
            end
          end
      end

      attr_accessor :site, :options, :space

      def initialize(args: [], site: nil, options: {})
        base = File.expand_path(args.join(" "), Dir.pwd)
        @site = site || self.class.scaffold(base)
        @options = options
        @space = management.spaces.find(ENV['CONTENTFUL_SPACE_ID'])
      end

      def sync!
        content_types.each do |model, schema|
          cfg = @site.config.dig('collections', model.pluralize)
          entries = client.entries(content_type: model)
          docs = entries.collect{|entry|
            Jekyll::Contentful::Document.new(entry, schema: schema, cfg: cfg)
          }
          docs.map(&:write!)
        end
      end

      def content_types
        @content_types ||= begin
          models = @space.content_types.all
          schema = models.collect do |model|

            fields = []
            references = []
            model.properties.dig(:fields).each do |field|
              if %w(Array Link).include?(field.type) && field.properties.dig(:linkType) != 'Asset'
                references.push(field)
              else
                fields.push(field)
              end
            end

            [model.id, {
              "fields" => fields.collect(&:id),
              "references" => references.collect{|ref|
                if ref.type == 'Array'
                  link_content_types = ref.items.validations.collect{|v| v.properties.dig(:linkContentType) }.flatten
                else
                  link_content_types = ref.validations.collect{|v| v.properties.dig(:linkContentType) }.flatten
                end

                if link_content_types.empty?
                  ref.id
                else
                  Hash[ref.id, link_content_types]
                end
              }
            }]
          end

          schema.reject!{|arr| (@site.config.dig('contentful', 'skip') || []).include? arr.first }
          schema_obj = Hash[schema]

          Hash[schema.collect{|name,obj|
            obj['references'] = obj['references'].collect{|type|
              begin
                if type.is_a? Hash
                  type, models = type.first
                  Hash[type, models.collect{|model| Hash[model, schema_obj[model]['fields']] }]
                else
                  Hash[type, schema_obj[type.singularize]['fields']]
                end
              rescue
                binding.pry
              end

            }.reduce({}, :merge)
            [name, obj]
          }]
        end
      end

      def client
        @client ||= self.class.send(:client)
      end

      def management
        @management ||= self.class.send(:management)
      end

    end
  end
end