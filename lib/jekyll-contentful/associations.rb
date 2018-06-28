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
            cfg.dig('associations').collect do |k, assoc|
              associations[k] = []

              # ...get all matching documents and concatenate them into one big array
              assoc.each do |collection, property|
                sel = get_associated_docs(doc, assoc.keys)
                associations[k].concat(sel)
              end

              # ...sort the array against the front-matter for the current document
              order = doc.data[k]
              associations[k].uniq!.sort_by_arr!(order, 'id')
            end


            # set the associated docs back onto doc object so its exposed to Liquid
            doc.data['associations'] = associations
          end
        end
      end

      protected

        def get_associated_docs(owner, types_arr)
          # binding.pry
          get_docs_of_type(types_arr).select do |assoc_doc|
            owner.data['videos'].include?(assoc_doc.data['id'])
          end.uniq
        end

        def get_docs_of_type(arr)
          arr.collect{|t| @site.collections[t].docs }.flatten
        end

    end
  end
end