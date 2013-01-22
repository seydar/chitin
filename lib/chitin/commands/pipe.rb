module Chitin
  class Pipe
    include Runnable
  
    attr_accessor :parts
    attr_accessor :pids
  
    def initialize(*parts)
      @parts = parts

      super()
  
      link_all
    end
  
    # link everything together
    def link_all
      # move from left to right through the list
      # link the left one to the right one
      parts[1..-1].inject parts.first do |left, right|
        link left, right
        # return this, and shift the whole process one to the right
        right
      end
    end
  
    def link(left, right)
      # The pipe that we use to connect the dots
      r, w = IO.pipe
  
      # since left will want to write to STDOUT, we have to give it
      # something else it can write to.
      left > w

      # same thing for right, but with reading
      r > right
  
      # right will try to read from r until w is closed.
      # when w is closed, right will finish processing.
      # if we don't close this, right will never return
      w.close
      r.close # and we close r so that we don't have any open useless handles
    end
  
    # Like raw_run, but meant to be used in chaining.
    def run
      parts.each {|part| part[:run] }
      reset
  
      self
    end
  
    # Run them all but let the last run return its value
    def raw_run
      parts[0..-2].each {|part| part[:run] }
      result = parts.last[:raw_run]
      reset
  
      result
    end

    def wait
      parts.each {|part| part[:wait] }
  
      self
    end
  
    def reset
      parts.map {|part| part[:reset] }
      link_all # we have to refresh the pipes connecting everything
  
      self
    end
  
    def |(other)
      raise "#{other.class} needs to include Runnable" unless Runnable === other
  
      link parts.last, other
      parts << other
  
      self
    end
  
    def in
      @parts.first[:in]
    end
    def in=(other); @parts.first[:set_in, other]; end
  
    def out
      @parts.last[:out]
    end
    def out=(other); @parts.last[:set_out, other]; end
  
    def err
      @parts.last[:err]
    end
    def err=(other); @parts.last[:set_err, other]; end
  
    def to_s
      "#{self.in} > #{parts.map {|p| p[:to_s] }.join ' | '} > #{self.out}"
    end
  
    def returning
      parts.last[:returning]
    end
  
  end
end

