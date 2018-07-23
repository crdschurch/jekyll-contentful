require 'active_support/inflector'
require 'contentful/management'

module Jekyll
  module Contentful
    class ContentTypes
      class << self

        attr_accessor :space, :entries, :config

        def space
          @space ||= begin
            management.spaces.find(ENV['CONTENTFUL_SPACE_ID'])
          end
        end

        def management
          @management ||= begin
            ::Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
          end
        end

        def load_jekyll_config(dir=nil)
          @config ||= begin
            file = File.join(dir || File.expand_path(__dir__), '_config.yml')
            yml = File.exist?(file) ? YAML.load(File.read(file)) : {}
            yml.dig('contentful') || {}
          end
        end

        def all(project_dir=nil)
          load_jekyll_config(project_dir)

          @entries ||= begin
            models = space.content_types.all
            schema = models.collect do |model|
              fields = []
              references = []
              model.properties.dig(:fields).each do |field|
                if %w(Array Link).include?(field.type) && field.properties.dig(:linkType) != 'Asset'
                  references.push(field)
                else
                  fields.push(field)
                end
              end

              [model.id, {
                "fields" => fields.collect(&:id),
                "references" => references.collect{|ref|
                  if ref.type == 'Array'
                    link_content_types = ref.items.validations.collect{|v| v.properties.dig(:linkContentType) }.flatten
                  else
                    link_content_types = ref.validations.collect{|v| v.properties.dig(:linkContentType) }.flatten
                  end

                  if link_content_types.empty?
                    ref.id
                  else
                    Hash[ref.id, link_content_types]
                  end
                }
              }]
            end

            schema.reject!{|arr|
              (config.dig('exclude') || []).include? arr.first
            }
            schema_obj = Hash[schema]

            Hash[schema.collect{|name,obj|
              obj['references'] = obj['references'].collect{|type|
                if type.is_a? Hash
                  type, models = type.first
                  Hash[type, models.collect{|model| Hash[model, schema_obj[model]['fields']] }]
                else
                  Hash[type, schema_obj[type.singularize]['fields']]
                end
              }.reduce({}, :merge)
              [name, obj]
            }]
          end
        end

      end
    end
  end
end