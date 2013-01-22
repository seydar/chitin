module Chitin
  class StringMethod
    __sweep__ :[]

    include Runnable
  
    attr_reader :chains
    attr_reader :pid
  
    def initialize(*arr, &block)
      super()

      raise "Need at least a method name" unless [String, Symbol].include? arr.first.class
      @chains = []
      latest  = [*arr]
      latest << block if block
      @chains << latest
    end

    def method_missing(*arr, &block)
      latest  = [*arr]
      latest << block if block
      @chains << latest
      self # chainable
    end

    private

    def result
      val = self[:in].read
      @chains.each do |arr|
        val = if Proc === arr.last
                val.send *arr[0..-2], &arr[-1]
              else
                val.send *arr
              end
      end
  
      val
    end
  
    # this is runs the method on the input
    # and then writes the output to self.out
    # used in piping
    def run
      child = fork do
        self[:out].write result
  
        close_all
      end
  
      close_all
      reset
  
      @pid = child

      self
    end
  
    # like #run, except instead of writing the output
    # we simply return it
    # used when a StringMethod is the LAST item in a pipe
    def raw_run
      res = result
      close_all
      reset
  
      res
    end
  
    def wait
      @pid && Process.wait(@pid)
    end
  
    def reset
      self.in, self.out, self.err = nil
    end

    def returning
      :ruby
    end
  
    # fix this. What if someone passes an executable as an argument?
    def to_s
      @chains.map do |arr|
        "#{arr[0]}(#{arr[1..-1].map {|a| a.is_a?(Proc) ? "&block" : a.inspect }.join ', '})"
      end.join '.'
    end
  
    def inspect
      "#<StringMethod #{to_s}>"
    end
  end
end

# class Proc
#   # So let's quick chat about what including Runnable to a proc means.
#   # It means that it can be chained with pipes.
#   # It also means that you can run private methods with #[].
#   # The important thing isn't that you can run private methods. You could
#   # do that since the beginning of time.
#   # The take-away is that it OVERRIDES #[]. In the words of Joe Biden,
#   # this is a big fucking deal.
#   #
#   # whatdo.jpg
#   #
#   # This means that you cannot, in the environment of Chitin, use
#   # Proc#[] for anything other than accessing private methods. This
#   # means it does not play well with others. This is what we in the biz
#   # call bad.
#   #
#   # Maybe I shouldn't even offer this as a feature.
#   undef_method :[]
#   include Chitin::Runnable
# 
#   # # access private methods
#   # def [](*args)
#   #   if method(args.first)
#   #     method(args.first).call *args[1..-1]
#   #   else
#   #     raise NoMethodError.new("undefined method" +
#   #                             "`#{args.first}' for #{self}:#{self.class}")
#   #   end
#   # end
# 
#   def |(other)
#     Pipe.new self, other
#   end
# 
#   private
# 
#   def run
#     child = fork do
#       self.out.puts call(self.in)
# 
#       close_all
#     end
# 
#     close_all
#     reset
# 
#     @pid = child
#   end
# 
#   def raw_run
#     val = call self.in
#     
#     close_all
#     reset
#     val
#   end
# 
#   def wait
#     Process.wait @pid
#   end
# 
#   def reset
#     self.in, self.out, self.err = nil
#   end
# end

