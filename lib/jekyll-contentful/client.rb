require 'active_support/all'
require 'contentful/management'

module Jekyll
  module Contentful
    class Client

      attr_accessor :site, :options, :space, :docs, :entries, :log_color

      include ::TextHelper

      def initialize(args: [], site: nil, options: {})
        base = File.expand_path(args.join(" "), Dir.pwd)
        @site = site || self.class.scaffold(base)
        @options = options
        @entries = {}
        @log_color = 'green'
      end

      def sync!
        nfo = "#{client.configuration.dig(:space)} (#{client.configuration.dig(:environment)})"
        log("Syncing content from Contentful API... #{nfo}\n", color: "green")
        colors = ColorizedString.colors.shuffle
        @docs ||= begin
          Hash[content_types.each_with_index.collect do |content_type, index|
            @log_color = colors[index % (colors.count - 1)]
            model, schema = content_type

            if @options.dig('clean')
              rm(model.pluralize)
            end
            cfg = @site.config.dig('collections', model.pluralize)
            entries = fetch_entries(model)
            docs = entries.collect{|entry|
              Jekyll::Contentful::Document.new(entry, schema: schema, cfg: cfg)
            }
            files = docs.collect{|entry|
              if entry.write!
                STDOUT.write ColorizedString.new('.').send(log_color)
              end
            }
            log "\n#{pluralize(files.count, model)} imported.\n"
            [model.pluralize, docs]
          end]
        end
      end

      def collections_glob(type)
        path = File.join(@site.collections_path, "_#{type}/*")
        Dir.glob(path)
      end

      def rm(type)
        log("Removing collection directory '_#{type.pluralize}'")
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
            environment: (ENV['CONTENTFUL_ENV'] || 'master'),
            reuse_entries: true
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

        def fetch_entries(type)
          unless @entries.keys.include?(type)
            @entries[type] = []
          end

          params = query_params.merge({
            skip: @entries[type].count,
            content_type: type
          })

          log("Querying '#{type.pluralize}' with the following parameters...")
          log(params.to_json)

          this_page = client.entries(params).to_a
          @entries[type].concat(this_page)
          if this_page.size == 1000
            fetch_entries(type)
          else
            log("#{pluralize(@entries[type].count, type)} returned.")
            @entries[type]
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

          if !options.dig('query').nil?
            CGI.parse(options.dig('query')).each do |k,v|
              args[k] = v.first
            end
          end

          args
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

        def client_endpoint(params)
          uri = [
            client.base_url,
            client.environment_url('/entries'),
            '?access_token=...',
            URI.encode_www_form(params)
          ].join()
        end

        def log(a, b=nil, color: nil)
          a = ColorizedString.new(a).send(color || @log_color)
          b = ColorizedString.new(b).send(color || @log_color) unless b.nil?
          Jekyll.logger.info a, b
        end

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

    end
  end
end