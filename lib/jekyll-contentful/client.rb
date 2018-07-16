require 'active_support/inflector'

module Jekyll
  module Contentful
    class Client

      class << self
        attr_accessor :entries

        def store_entries(type_id, limit)
          self.entries ||= {}
          self.entries[type_id.to_sym] = fetch_entries(type_id, limit: limit)
        end

        def scaffold(app_root)
          overrides = Jekyll::Configuration.new.read_config_file(File.join(app_root, '_config.yml'))
          site_config = Jekyll::Utils.deep_merge_hashes(Jekyll::Configuration::DEFAULTS, overrides.merge({
            "source" => app_root,
            "destination" => File.join(app_root, '_site')
          }))
          Jekyll::Site.new(site_config)
        end

        private

          def fetch_entries(type_id, limit: nil, entries: [])
            this_page = client.entries(content_type: type_id, limit: (limit || 1000), skip: entries.size).to_a
            entries.concat(this_page)
            this_page.size == 1000 ? fetch_entries(type_id, entries: entries) : entries
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

      end

      attr_accessor :site, :options

      def initialize(args: [], site: nil, options: {})
        base = File.expand_path(args.join(" "), Dir.pwd)
        @site = site || self.class.scaffold(base)
        @options = options
      end

      def sync!
        add_belongs_to_for_every_has_many!
        # write everything to disk
        documents.map(&:write!)
      end

      def add_belongs_to_for_every_has_many!
        documents.map do |doc|

          # for every document, are there any associations?
          refs = (doc.frontmatter.keys & doc.associations.keys)
          if refs.length > 0

            # reduce all entries down to just those that are association with document
            related = documents.select{|e|
              doc.association_ids.include? e.frontmatter.dig('id')
            }
            # for each related document, add this document to frontmatter
            related.map do |r_entry|
              yml = r_entry.frontmatter[doc.frontmatter.dig('content_type')] ||= []
              yml.push(doc.frontmatter.dig('id'))
            end

          end
        end
      end

      private

        def documents
          @documents ||= begin
            Hash[collections.collect{|type|
              rm(type)
              [type, get_entries_of_type(type)]
            }].values.flatten
          end
        end

        def get_entries_of_type(type)
          type_cfg = cfg(type)
          type_id = type_cfg.dig('id')
          entries = self.class.store_entries(type_id, @options.dig('limit'))
          entries.collect{|entry| Jekyll::Contentful::Document.new(entry, type_cfg) }
        end

        def collections
          @collections ||= begin
            collections = @site.config.dig('contentful').keys
            if @options.dig('collections').nil?
              collections
            else
              collections & @options.dig('collections')
            end
          end
        end

        def cfg(type)
          @site.config.dig('contentful', type).merge({ 'collection_name' => type })
        end

        def collections_glob(type)
          path = File.join(@site.collections_path, "_#{type}/*")
          Dir.glob(path)
        end

        def rm(type)
          if @options.dig('force')
            collections_glob(type).each do |file|
              FileUtils.remove_entry_secure(file) if File.exist?(file)
            end
          end
        end

        def client
          @client ||= self.class.send(:client)
        end

    end
  end
end