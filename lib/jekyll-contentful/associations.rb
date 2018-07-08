module Jekyll
  module Contentful
    class Associations

      attr_accessor :site, :defs

      def initialize(site)
        @site = site
        @defs = site.config.dig('contentful', 'content_types').select{|type, cfg| cfg.keys.include?('has_many') }
      end

      def run!
        @defs.each do |content_model, cfg|

          # Loop through all the documents for this content_model
          @site.collections[content_model].docs.each do |doc|
            associations = {}

            cfg.dig('has_many').each do |name, models|
              # ...get all matching documents and concatenate them into one big array
              associations[name] = get_associated_docs(doc, name, models)

              # ...sort the array against the front-matter for the current document
              order = doc.data[name]
              associations[name].sort_by_arr!(order, 'id')
            end

            # put associations on doc object so they're exposed to Liquid
            doc.data['associations'] = associations
          end
        end
      end

      protected

        def get_associated_docs(owner, name, models)
          get_docs_of_type(models).select do |doc|
            begin
              owner.data[name].include?(doc.data['id'])
            rescue
              false
            end
          end.uniq
        end

        def get_docs_of_type(arr)
          arr.collect{|t| @site.collections[t].docs }.flatten
        end

    end
  end
end