class Array
  def sort_by_arr!(order, key)
    self.sort! { |a,b| order.index(a.data[key]) <=> order.index(b.data[key]) }
  end

  def difference(other)
    h = other.each_with_object(Hash.new(0)) { |e,h| h[e] += 1 }
    reject { |e| h[e] > 0 && h[e] -= 1 }
  end
end