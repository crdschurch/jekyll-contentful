module Jekyll
  module Contentful
    class Associations

      attr_accessor :site, :types

      def initialize(site)
        @site = site
        @types = site.config.dig('contentful', 'content_types').select{|type, cfg| cfg.keys.include?('associations') }
      end

      def run!
        @types.each do |type, cfg|

          # Loop through all the documents for collection types specified in associations config
          @site.collections[type].docs.each do |doc|
            associations = {}

            # For each associated collection...
            cfg.dig('associations').each do |mapping|
              ref, collections = mapping

              # ...get all matching documents and concatenate them into one big array
              associations[ref] = get_associated_docs(doc, mapping)

              # ...sort the array against the front-matter for the current document
              order = doc.data[ref]
              associations[ref].sort_by_arr!(order, 'id')
            end

            # put associated docs back onto doc object so its exposed to Liquid
            doc.data['associations'] = associations
          end
        end
      end

      protected

        def get_associated_docs(owner, mapping)
          ref, collections = mapping

          get_docs_of_type(collections).select do |assoc_doc|
            begin
              owner.data[ref].include?(assoc_doc.data['id'])
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