require 'active_support/all'
require 'contentful/management'

module Jekyll
  module Contentful
    class Client

      class << self
        def scaffold(app_root)
          overrides = Jekyll::Configuration.new.read_config_file(File.join(app_root, '_config.yml'))
          site_config = Jekyll::Utils.deep_merge_hashes(Jekyll::Configuration::DEFAULTS, overrides.merge({
            "source" => app_root,
            "destination" => File.join(app_root, '_site')
          }))
          Jekyll::Site.new(site_config)
        end
      end

      attr_accessor :site, :options, :space, :docs, :entries

      def initialize(args: [], site: nil, options: {})
        base = File.expand_path(args.join(" "), Dir.pwd)
        @site = site || self.class.scaffold(base)
        @options = options
        @entries = {}
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
            entries = fetch_entries(model)
            docs = entries.collect{|entry|
              Jekyll::Contentful::Document.new(entry, schema: schema, cfg: cfg)
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
        @client ||= begin
          ::Contentful::Client.new(
            access_token: ENV['CONTENTFUL_ACCESS_TOKEN'],
            space: ENV['CONTENTFUL_SPACE_ID'],
            environment: (ENV['CONTENTFUL_ENV'] || 'master')
          )
        end
      end

      def management
        @management ||= ::Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
      end

      def space
        @space ||= management.spaces.find(ENV['CONTENTFUL_SPACE_ID'])
      end

      private

        def fetch_entries(type_id)
          @entries[type_id] = [] unless @entries.keys.include?(type_id)
          params = query_params.merge({ skip: @entries[type_id].count })
          this_page = client.entries(params).to_a
          @entries[type_id].concat(this_page)
          if this_page.size == 1000
            fetch_entries(type_id)
          else
            @entries[type_id]
          end
        end

        def query_params
          args = {
            limit: (options.dig('limit') || 1000),
            order: sort_order(options.dig('order'))
          }
          if !options.dig('recent').nil?
            args['sys.createdAt[gte]'] = eval(options.dig('recent')).strftime('%Y-%m-%d') rescue nil
          end
          args
        rescue Exception => e
          binding.pry
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

    end
  end
end