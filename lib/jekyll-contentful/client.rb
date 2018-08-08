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

      attr_accessor :site, :options, :space, :docs

      def initialize(args: [], site: nil, options: {})
        base = File.expand_path(args.join(" "), Dir.pwd)
        @site = site || self.class.scaffold(base)
        @options = options
      end

      def sync!
        docs.values.flatten.map(&:write!)
      end

      def docs
        @docs ||= begin
          Hash[content_types.collect do |model, schema|
            if @options.dig('clean')
              rm(model.pluralize)
            end

            cfg = @site.config.dig('collections', model.pluralize)
            cfl = @site.config.dig('contentful', model.pluralize)

            entries = client.entries(content_type: model)
            docs = entries.collect{|entry|
              Jekyll::Contentful::Document.new(entry, schema: schema, cfg: cfg, cfl: cfl)
            }
            [model.pluralize, docs]
          end]
        end
      end

      def collections_glob(type)
        path = File.join(@site.collections_path, "_#{type}/*")
        Dir.glob(path)
      end

      def rm(type)
        collections_glob(type).each do |file|
          FileUtils.remove_entry_secure(file) if File.exist?(file)
        end
      end

      def content_types
        @content_types ||= Jekyll::Contentful::ContentTypes.all(@site.config.dig('source'), @options)
      end

      def client
        @client ||= self.class.send(:client)
      end

      def management
        @management ||= self.class.send(:management)
      end

      def space
        @space ||= management.spaces.find(ENV['CONTENTFUL_SPACE_ID'])
      end

    end
  end
end