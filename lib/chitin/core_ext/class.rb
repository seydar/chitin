class Class
  def __sweep__(*save)
    instance_methods.each do |meth|
      next if save.include? meth
      private meth
    end
  end
end

