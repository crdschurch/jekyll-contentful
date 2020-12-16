module Jekyll
  module Contentful
    class Client

      attr_accessor :site, :options, :space, :docs, :entries, :log_color

      def initialize(args: [], site: nil, options: {})
        base = File.expand_path(args.join(" "), Dir.pwd)
        @site = site || self.class.scaffold(base)
        @options = options
        @entries = {}
        @log_color = 'green'
      end

      def sync!
        nfo = "#{client.configuration.dig(:space)} (#{client.configuration.dig(:environment)})"

        str = "Syncing content from Contentful API"
        str += " for distribution channels: #{distribution_channels}" if distribution_channels
        log("#{str}... #{nfo}\n", color: "green")

        colors = ColorizedString.colors.shuffle
        @docs ||= begin
          data = Hash[content_types.each_with_index.collect do |content_type, index|
            @log_color = colors[index % (colors.count - 1)]
            model, schema = content_type
            rm(model.pluralize) if @options.dig('clean')
            ct_cfg = @site.config.dig('contentful', model)
            cfg = @site.config.dig('collections', model.pluralize)
            entries = fetch_entries(model)
            docs = entries.collect{|entry|
              Jekyll::Contentful::Document.new(entry, schema: schema, cfg: cfg, ct_cfg: ct_cfg)
            }
            [model.pluralize, docs]
          end]
          Document.process_associations!(data)
          data.each_with_index.map do |(type, docs), index|
            @log_color = colors[index % (colors.count - 1)]
            imported_count = 0
            files = docs.collect do |entry|
              if entry.write!
                imported_count += 1
              end
            end
            log "#{imported_count}/#{docs.size} #{type.pluralize(imported_count)} imported."
            [type, docs]
          end.to_h
        end
      end

      def distribution_channels
        @distribution_channels ||= @options.dig('sites').try(:split, ',')
      end

      def distribution_channels_frontmatter_field
        @distribution_channels_frontmatter_field ||= begin
          (@site.config.dig('contentful', 'config', 'sites') || 'distribution_channels').intern
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
          @entries[type] ||= []
          params = {
            skip: @entries[type].count,
            limit: (options.dig('limit') || 1000)
          }

          if type != 'asset'
            params = query_params(type)
              .merge(params)
              .merge({
                content_type: type
              })
          end

          log("Querying '#{type.pluralize}' with the following parameters...")
          log(params.to_json)

          this_page = type == 'asset' ? client.assets(params).to_a : client.entries(params).to_a
          @entries[type].concat(this_page)
          if this_page.size == 1000
            fetch_entries(type)
          else

            # Exclude content not included in specified channels
            @entries[type].delete_if do |entry|
              d_field = distribution_channels_frontmatter_field
              if distribution_channels && content_types.dig(entry.content_type.id, 'fields').include?(d_field.to_s)
                target_channels = entry.fields.dig(d_field) || []
                (target_channels.collect{|c| c.dig('site') }.compact & distribution_channels).length === 0
              end
            end

            log("#{@entries[type].count} #{type.pluralize(@entries[type].count)} returned.")
            @entries[type]
          end
        end

        def query_params(type = nil)
          ct_cfg = @site.config.dig('contentful', type) || {}

          args = {
            limit: (ct_cfg.dig('limit') || options.dig('limit') || 1000),
            order: sort_order(ct_cfg.dig('order') || options.dig('order'))
          }

          if !options.dig('recent').nil?
            args['sys.createdAt[gte]'] = eval(options.dig('recent')).strftime('%Y-%m-%d') rescue nil
          end

          query = ct_cfg.dig('query') || options.dig('query')
          if query.present?
            CGI.parse(query).each { |k,v| args[k] = v.first }
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
