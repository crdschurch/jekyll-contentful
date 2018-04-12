require 'pry'

module Jekyll
  module Commands
    class Contentful < Command
      class << self

        def init_with_program(prog)
          prog.command(:hubspot) do |c|
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
          binding.pry

          # hubspot = Jekyll::Content::Importer.new(site)
          # payload = hubspot.run
          # payload.to_h.each do |collection, docs|
          #   unless docs.nil?
          #     FileUtils.mkdir_p("#{site.config['collections_dir']}/_#{collection.to_s}")
          #     docs.each do |doc|
          #       doc.write!(site, options.dig('force'))
          #     end
          #   end
          # end
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