module Chitin
  class Executable
    __sweep__ :[]

    include Runnable
  
    def initialize(path, *args)
      super()

      @path = path
      @args = process_args(args)
    end
  
    # EVERYTHING will be sent to the command. ERRTHANG!!!!
    def method_missing(name, *arr, &blk)
      setup name.to_s, *process_args(arr)
      self
    end

    private

    attr_accessor :args
    attr_accessor :path
    attr_accessor :pid
  
    def process_args(args)
      processed = args.map do |arg|
        if arg.is_a? Hash
          arg.map do |k, v|
            key = if k.is_a? Symbol
                    "#{k.to_s.size > 1 ? '--' : '-'}#{k}"
                  else
                    k
                  end

            val = v.is_a?(FSObject) ? v.to_a : v

            [key, val]
          end
        else
          #a = arg.is_a?(FSObject) ? arg.to_a : arg
          #pp a.map(&:to_s) if arg.is_a? FSObject
          arg
        end
      end
  
      processed.flatten.map {|a| a.to_s }
    end

    def args
      @args ||= []
    end

    # prep the executable to run with the arguments +subc+ and +args+
    def setup(subc, *arr)
      # we have to use +@args+ here because otherwise we'd have to use the +=
      # method which would trigger an explosion of +method_missing+
      @args += [subc.to_s]
      @args += arr.map {|a| a.to_s }
      self # need to return this so that the shell can just run it
    end

    def returning
      :io
    end
  
    def run
      child = fork do
        # Like the comments in +open_pipes+, the user writes to +@in+.
        # Then our executable now will read from +@in+. OH HEY NO WAY
        # since executables normally read from STDIN, we can link them.
        IO.open(0).reopen self[:in] # STDIN to the program comes from 
        IO.open(1).reopen self[:out]
        IO.open(2).reopen self[:err]
  
        # These can be closed because there is already an opening
        # via IO 0, 1, and 2.
        close_all
        # And it is important that they be closed, otherwise
        # we'll have a hanging pipe that will hold everything up.
  
        exec path, *args
      end
  
      close_all
  
      reset
      @pid = child
    end
  
    def wait
      Process.wait @pid
    rescue Interrupt => e
      Process.kill "HUP", @pid
    end
  
    def reset
      @opened = false
      self.in, self.out, self.err = nil
    end
  
    def each_line
      proc do |inp|
        # since out is only open for writing (since it is supposed to be used
        # by the process itself, like with puts and print), we need to make our
        # OWN pipe
        r, w = IO.pipe
        inp > self > w
        run # since we let it run in the background, we're not gonna call +#wait+
  
        # lil bits at a time
        while (chunk = r.gets)
          yield chunk
        end
  
        self
      end
    end

    def inspect
      "#<Chitin::Executable #{super}>"
    end

    def to_s
      arr = process_args(args)
  
      [path, *arr.flatten].join ' '
    end
  
  end
end

