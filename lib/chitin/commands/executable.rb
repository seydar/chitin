module Chitin
  class Executable
    # this is needed to work in tandem with #method_missing.
    # this will sweep all inherited methods BUT #[] under the rug.
    __sweep__ :[]

    include Runnable
  
    def initialize(path, *args)
      super()

      @path = path
      @args = process_args(args)
      @suspended = false
    end
  
    # EVERYTHING will be sent to the command. ERRTHANG!!!!
    def method_missing(name, *arr, &blk)
      if @suspended
        super(name, *arr, &blk)
      else
        setup name.to_s, *process_args(arr)
        self
      end
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
          # I'm leaving this here so that I know what went down in this
          # battlefield. I tried automatically expanding FileObject globs, but
          # that in conjunction with * means things get expanded twice,
          # resulting in a lot of duplicates.
          #
          # Maybe an answer is to get rid of * and only do automatic expansion
          # for executables.
          #
          # NO YOU CAN'T! What if you want to pass a directory to program that
          # you have save as a Chitin::Directory? It would end up being globbed
          # open which is NOT what you wanted. Globbing must be done explicitly.
          #
          # a = arg.is_a?(FSObject) ? arg.to_a : arg
          # pp a.map(&:to_s) if arg.is_a? FSObject
          # a
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

      # these set them to nil (duh)
      self.in, self.out, self.err = nil

      # so that THESE can then reopen them
      set_in  STDIN
      set_out STDOUT
      set_err STDERR
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

    # Make it so you can treat it like a normal object.
    # This stops method forwarding
    def suspend
      @suspended_methods = private_methods.dup
      @suspended_methods.each {|m| public m }

      @suspended = true
    end

    def unsuspend
      @suspended_methods.each {|m| private m }
      @suspended_methods = []
      @suspended = false
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

