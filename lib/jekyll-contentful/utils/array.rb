class Array
  def sort_by_arr!(order, keys)
    self.sort! { |a,b| order.index(a.dig(*keys)) <=> order.index(b.dig(*keys)) }
  end
end