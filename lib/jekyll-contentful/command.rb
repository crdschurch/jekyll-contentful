require 'contentful'

module Jekyll
  module Commands
    class Contentful < Command
      class << self

        def init_with_program(prog)
          prog.command(:contentful) do |c|
            c.alias(:cf)
            c.syntax "contentful [options]"
            c.description 'Imports data from Contentful'
            c.option 'collections', '-c', '--collections COL1[,COL2]', Array, 'Return content for specific collections'
            c.option 'limit', '-n', '--limit N', Integer, 'Limit the number of entries returned'

            c.action do |args, options|
              Jekyll::Contentful::Client.new(args: args, options: options).sync!
            end
          end
        end

      end
    end
  end
end