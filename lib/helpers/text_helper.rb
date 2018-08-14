module TextHelper

  def pluralize(count, singular, plural_arg = nil, plural: plural_arg)
    word = if (count == 1 || count =~ /^1(\.0+)?$/)
      singular
    else
      plural || singular.pluralize
    end
    "#{count || 0} #{word}"
  end

end