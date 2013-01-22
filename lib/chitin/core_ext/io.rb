class IO
  def >(executable)
    executable[:set_in, self]
    executable
  end
end

