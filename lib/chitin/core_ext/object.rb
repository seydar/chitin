class Object

  # it does NOT return self, but rather the value of block.
  # if no block is given, it returns nil
  def bottle # since it's not tap
    if block_given?
      yield self
    end
  end

  # access private methods
  def [](*args)
    if method(args.first)
      method(args.first).call *args[1..-1]
    else
      raise NoMethodError.new("undefined method" +
                              "`#{args.first}' for #{self}:#{self.class}")
    end
  end
end

