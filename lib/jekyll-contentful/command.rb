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
            c.option 'limit', '-n', '--limit N', Integer, 'Limit the number of entries returned, e.g. "--limit 10"'
            c.option 'recent', '-d', '--recent DATE', String, 'Limit the number of entries returned by time, e.g. "--recent 1.day.ago"'
            c.option 'clean', '-f', '--force', 'Remove existing collections data prior to importing'
            c.action do |args, options|
              Jekyll::Contentful::Client.new(args: args, options: options).sync!
            end
          end
        end

      end
    end
  end
end