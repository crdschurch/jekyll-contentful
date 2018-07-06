require 'contentful'

module Jekyll
  module Commands
    class Contentful < Command
      class << self

        def init_with_program(prog)
          prog.command(:contentful) do |c|
            c.syntax "contentful [options]"
            c.description 'Imports data from Contentful'
            c.action do |args, options|
              Jekyll::Contentful::Client.new(args: args).sync!
            end
          end
        end

      end
    end
  end
end