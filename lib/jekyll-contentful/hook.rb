Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  doc.data['body'] = doc.content
end