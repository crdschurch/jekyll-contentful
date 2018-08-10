module Jekyll
  module Contentful
    module Loggable
      def log(a, b=nil, color: nil)
        a = color ? ColorizedString.new(a).send(color) : a
        b = color && b.present? ? ColorizedString.new(b).send(color) : b
        Jekyll.logger.info a, b
      end
    end
  end
end