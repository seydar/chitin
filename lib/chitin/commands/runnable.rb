module Chitin
  module Runnable

    def initialize
      set_in  STDIN
      set_out STDOUT
      set_err STDERR
    end

    def <(io)
      case io
      when IO, File
        self[:set_in, io]
      when String, FileObject
        f = File.open io.to_s, 'r'
        self[:set_in, f]
        f.close
      else
        raise "Unknown piping type: #{io.class}"
      end
  
      self
    end

    def >(io)
      case io
      when IO, File
        self[:set_out, io]
      when String, FileObject
        f = File.open io.to_s, 'w'
        self[:set_out, f]
        f.close
      else
        raise "Unknown piping type: #{io.class}"
      end
  
      self
    end

    def >>(io)
      case io
      when IO, File
        self[:set_out, io]
      when String, FileObject
        f = File.open io.to_s, 'a'
        self[:set_out, f]
        f.close
      else
        raise "Unknown piping type: #{io.class}"
      end
  
      self
    end

    def ^(io)
      case io
      when IO, File
        self[:set_err, io]
      when String, FileObject
        f = File.open io.to_s, 'w'
        self[:set_err, f]
        f.close
      else
        raise "Unknown piping type: #{io.class}"
      end
  
      self
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

    def bg!; @bg = true; self; end
    def bg?; @bg; end
    def fg?; !@bg; end

    def |(other); Pipe.new self, other; end
    alias_method :<=>, :|

    private

    attr_accessor :bg
    attr_accessor :in
    attr_accessor :out
    attr_accessor :err
  
    # I'm pretty sure this would induce a memory leak if Ruby
    # weren't GCed. Suggestions are appreciated.
    def set_in(other)
      r, w = IO.pipe
      w.close
      self[:in=, r]
      self[:in].reopen other
    end
  
    # I'm pretty sure this would induce a memory leak if Ruby
    # weren't GCed. Suggestions are appreciated.
    def set_out(other)
      r, w = IO.pipe
      r.close
      self[:out=, w]
      self[:out].reopen other
    end
  
    # I'm pretty sure this would induce a memory leak if Ruby
    # weren't GCed. Suggestions are appreciated.
    def set_err(other)
      r, w = IO.pipe
      r.close
      self[:err=, w]
      self[:err].reopen other
    end
  
    # if one of the following is nil, bad things happen. this is deliberate.
    # is it wise? that's an exercise left to the reader.
    def close_all
      self[:in].close
      self[:out].close
      self[:err].close
    end

    # These methods need to be implemented by those including this module
    def returning; raise "Not Yet Implemented"; end
    def wait; raise "Not Yet Implemented"; end
    def reset; raise "Not Yet Implemented"; end
    def run; raise "Not Yet Implemented"; end

    # Generally the same as +run+, except for the ruby commands
    # they return real ruby that can be given back to the user.
    def raw_run
      run
    end
  end
end

