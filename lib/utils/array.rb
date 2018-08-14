class Array
  def sort_by_arr!(order, key)
    self.sort! { |a,b| order.index(a.data[key]) <=> order.index(b.data[key]) }
  end
end