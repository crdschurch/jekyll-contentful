require 'active_support/inflector'

class ColorizedString < String
  def colorize(color_code)
    name = self.class.color_codes.key(color_code).to_s.humanize
    "\e[#{color_code}m#{name}\e[0m"
  end

  def method_missing(m, *args, &block)
    if color_code = self.class.color_codes.dig(m)
      colorize(color_code)
    else
      super
    end
  end

  class << self
    def colors
      color_codes.keys
    end

    def color_codes
      {
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36
      }
    end
  end

end
