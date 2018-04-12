require 'pry'
require 'contentful'

module Jekyll
  module Commands
    class Contentful < Command
      class << self

        def init_with_program(prog)
          prog.command(:contentful) do |c|
            c.syntax "contentful [options]"
            c.description 'Imports data from Contentful'
            c.option 'force', '-f', '--force', 'Overwrite local data'
            c.action do |args, options|
              Jekyll::Commands::Contentful.process!(args, options)
            end
          end
        end

        def process!(args, options)
          site = scaffold(args)
          client = ::Contentful::Client.new(
            access_token: ENV['CONTENTFUL_ACCESS_TOKEN'],
            space: ENV['CONTENTFUL_SPACE_ID']
          )

          content_types = site.config.dig('contentful', 'content_types').keys
          content_types.each do |type|
            type_cfg = site.config.dig('contentful', 'content_types', type).merge({ 'collection_name' => type })
            type_id = type_cfg.dig('id')
            documents = client.entries(content_type: type_id).collect{|c| Jekyll::Contentful::Document.new(c, type_cfg) }
            documents.map(&:write!)
          end
        end

        def scaffold(args)
          app_root = File.expand_path(args.join(" "), Dir.pwd)
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