module Chitin
  class Sandbox
    attr_reader :previous

    def initialize
      @binding  = binding
      @previous = nil
    end
  
    def inspect
      "(sandbox)"
    end
  
    def evaluate(code)
      self.previous = eval code, @binding
    end

    def previous=(val)
      @previous = val
      eval "_ = @previous", @binding
    end
  end
end

