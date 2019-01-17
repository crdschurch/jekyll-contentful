module Jekyll
  module Contentful
    class ContentTypes
      class << self

        attr_accessor :space, :config, :models

        def all(project_dir=nil, options={})
          load_jekyll_config(project_dir)
          schema = Hash[get_schema]
          included_collections = (options.dig('collections') || {})
          if included_collections.empty?
            _schema = schema
          else
            _schema = schema.select {|k,v| (included_collections & [k, k.singularize]).present? }
          end
          Hash[_schema.collect{|name,obj|
            obj['references'] = obj['references'].collect{|type|
              if !models.include?(type)
                if type.is_a? Hash
                  type, models = type.first
                  Hash[type, models.collect{|model| Hash[model, schema.dig(model, 'fields')] }]
                else
                  Hash[type, schema[type.singularize]['fields']]
                end
              end
            }.compact.reduce({}, :merge)
            [name, obj]
          }]
        end

        private

          def get_models
            space.content_types.all
          end

          def get_fields(model)
            output = OpenStruct.new(fields: [], references: [])
            model.properties.dig(:fields).each do |field|
              if %w(Array Link).include?(field.type) && field.properties.dig(:linkType) != 'Asset'
                output.references.push(field)
              else
                output.fields.push(field)
              end
            end
            output
          end

          def get_schema
            @models = get_models
            schema = @models.collect do |model|
              model_details = get_fields(model)
              [model.id, {
                "fields" => model_details.fields.collect(&:id),
                "references" => model_details.references.collect(&parse_reference_field)
              }]
            end
            schema.reject{|arr| (config.dig('exclude') || []).include? arr.first }
          end

          def parse_reference_field
            -> (field) {
              content_types = begin
              if field.type == 'Array'
                field.items.validations.collect{|v| v.properties.dig(:linkContentType) }.flatten
              else
                field.validations.collect{|v| v.properties.dig(:linkContentType) }.flatten
                end
              end
              if content_types.empty?
                field.id
              else
                Hash[field.id, content_types]
              end
            }
          end

          def space
            @space ||= begin
              management.environments(ENV['CONTENTFUL_SPACE_ID']).find(ENV['CONTENTFUL_ENV'] || 'master')
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

      end
    end
  end
end