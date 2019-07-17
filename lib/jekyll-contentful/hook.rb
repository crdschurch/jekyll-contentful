Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  doc.data['body'] = doc.content
end

Jekyll::Hooks.register :site, :after_init do |site|
  if site.config['contentful']
    # For every contentful mapping in _config.yml...
    site.config['contentful'].each do |h|
      content_type, options = h

      # If there's a query key...
      if options.respond_to?('keys') && options.keys.try(:include?,'query')
        # If there's a string that looks like this: {{env.SOME_VALUE}}...
        if captures = options['query'].match(/{{env.([^}]*)}}/).try(:captures)
          captures.each do |k|
            # Replace string with an ENV variable of the same name....
            query = options['query'].gsub(/{{env.#{k}}}/, ENV[k])
            site.config['contentful'][content_type]['query'] = query
          end
        end
      end
    end
  end
end