module Jekyll
  module Contentful
    class Client

      attr_accessor :site

      def initialize(args: [], site: nil)
        base = File.expand_path(args.join(" "), Dir.pwd)
        @site = site || self.class.scaffold(base)
      end

      def sync!
        content_types.each do |type|
          rm(type)
          documents = get_entries(type)
          documents.map(&:write!)
        end
      end

      private

        def get_entries(type)
          type_cfg = cfg(type)
          type_id = type_cfg.dig('id')
          client.entries(content_type: type_id).collect{|entry| Jekyll::Contentful::Document.new(entry, type_cfg) }
        end

        def content_types
          @content_types ||= @site.config.dig('contentful', 'content_types').keys
        end

        def cfg(type)
          @site.config.dig('contentful', 'content_types', type).merge({ 'collection_name' => type })
        end

        def collections_glob(type)
          path = File.join(@site.collections_path, "_#{type}/*")
          Dir.glob(path)
        end

        def rm(type)
          collections_glob(type).each do |file|
            FileUtils.rm(file) if File.exist?(file)
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