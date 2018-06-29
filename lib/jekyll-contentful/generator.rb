require 'pry'

module Jekyll
  module Contentful
    class Generator < Jekyll::Generator

      safe true
      priority :low

      def generate(site)
        Jekyll::Contentful::Associations.new(site).run!
      end

    end
  end
end