class Hash
  # Returns a hash that only contains keys that are passed in selected_keys. This is different
  # from Hash#select, since that method returns an array of arrays.
  def only(*selected_keys)
    cpy = self.dup
    keys.each { |key| cpy.delete(key) unless selected_keys.map(&:to_s).include?(key) }
    cpy
  end
end