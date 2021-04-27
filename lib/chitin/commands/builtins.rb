# Things are contained in modules or functions so that they play well with
# code folding.
# Picked up that trick from Sinatra

require 'etc'
ENV['USER'] ||= Etc.getlogin
ENV['HOME'] ||= Etc.getpwent(ENV['USER']).dir

module Chitin
  module Builtins
    extend self

    # interface to Coolline
    def bind(key, &action)
      cool = defined?(SESSION) ? SESSION : Coolline
      cool.bind(key, &action)
    end

    def completion_proc(&block)
      @completion_proc = block
    end
  
    def pre_processing
      @pre_processing ||= {:default => []}
    end
  
    def pre_process(label=:default, &block)
      if label == :default
        pre_processing[label] << block
      else
        pre_processing[label] = block
      end
    end
  
    def post_processing
      @post_processing ||= {:default => []}
      @post_processing.default = Proc.new {|*args| args.size > 1 ? args : args.first }
      @post_processing
    end
  
    def post_process(label=:default, &block)
      if label == :default
        post_processing[label] << block
      else
        post_processing[label] = block
      end
    end

    # ruby's backtick doesn't chomp off the newline, which makes it more
    # or less useless for piping into other commands
    def `(*args)
      res = eval args.join

      if Runnable === res
        composed = res | L {|str| str }
        res = composed[:raw_run].chomp
        composed[:wait]
      end

      res.to_s
    end

    # Place the last argument on the line
    # This is a total hack. It would need proper parsing to accomodate for
    # strings with spaces in them.
    bind "\e." do |c|
      # Make it a proper string, first
      last_line = proper_string c.history[-2]
      last_arg = shellsplit_keep_quotes(c.history[-2]).last
      c.line << last_arg
      c.pos = c.line.length # go one beyond the last character position
    end

    # Quote the word around or before the cursor.
    # Useful for when you finish typing something and think "damn i'd like this
    # in quotes"
    bind ?\C-q do |c|
      if beg = c.word_beginning_before(c.pos) and last = c.word_end_before(c.pos) and
         not (["'", '"'].include?(c.line[beg..last][0, 1]) &&
              ["'", '"'].include?(c.line[beg..last][-1, 1]))
        c.line[beg..last] = '"' + c.line[beg..last] + '"'
        c.pos = last + 3 # 2 for the quotes and 1 for the cursor
      end
    end

    # Do nothing. this is so that we don't accidentally delete a word we're trying to quote
    bind(?\C-w) {}

    # Automatically add *f(..) around something
    bind ?\C-f do |c|
      if beg = c.word_beginning_before(c.pos) and last = c.word_end_before(c.pos)
        c.line[beg..last] = '*f(' + c.line[beg..last] + ')'
        c.pos = last + 5 # 4 for the characters and 1 for the cursor
      end
    end

    # Clear the line, don't add it to history
    bind ?\C-g do |c|
      c.line.clear
      c.pos = 0
    end

    # Clear the line, add it to history
    bind ?\C-d do |c|
      # Save the current line
      c.history[-1] = c.line if c.history.size != 0
      c.history.index = c.history.size
      c.history.save_line

      # And prep the new one
      c.instance_variable_set :@line, ""
      c.pos = 0
      c.history.index = c.history.size - 1
      c.history << c.line
    end
  
    module Prompts
      # The standard prompt. Must return a string. Override this to provide
      # a custom prompt.
      def prompt
        "#{ENV['USER']}: #{short_pwd} % "
      end

      # Get the elapsed time of the last command.
      def last_elapsed
        SESSION.last_elapsed || 0.0
      end

      def last_elapsed_formatted
        hours = (last_elapsed / 3600).floor
        min   = ((last_elapsed - 3600 * hours) / 60).floor
        sec   = last_elapsed - 3600 * hours - 60 * min

        if hours > 0
          "%02d:%02d:%f" % [hours, min, sec]
        elsif min > 0
          "%02d:%f" % [min, sec]
        else
          "%f" % sec
        end
      end

      # My personal fancy shell.
      # On the first line it has the time, elapsed time of the last
      # run command, and the shortened working directory.
      # On the second line, it has three colored dots.
      def time_elapsed_working_multiline_prompt
        "(".purple + Time.now.to_s + ") ".purple +
          "(".purple + "last => " + "#{last_elapsed_formatted}".cyan + ") ".purple +
          "(".purple + short_pwd.yellow + ")\n".purple +
          '.'.red + '.'.yellow + '.'.cyan + ' '
      end

      # Minimalist.
      def minimalist_prompt
        '.'.red + '.'.yellow + '.'.cyan + ' '
      end
    end
    include Prompts
  
    # I'm putting these in their own module so that you can compress them easily
    # using code folding. Sinatra-style, baby.
    module Aliases
      # Basic helper commands for shell usability
      def cd(path=ENV['HOME']); Dir.chdir path; pwd; end
      def pwd; Dir.pwd; end
      def short_pwd
        home = ENV['HOME']
        pwd.start_with?(home) ? pwd.sub(home, '~') : pwd
      end
      def ll(*a); ls '-hGl', *a; end
      def la(*a); ls '-haGl', *a; end
      def exeunt; puts 'Fare thee well...'; exit 0; end
      def x; exeunt; end
      def c; clear; end
  
      # required because `gem` is a ruby method as well
      def gem(*a); raw_exec("gem", *a); end
      def all; D('.'); end

      def to_num; L {|i| i.to_i }; end
      def p(*args)
        args.map do |arg|
          if Runnable === arg
            puts arg[:inspect]
          else
            puts arg.inspect
          end
        end

        # i know puts returns nil and p returns the object, but this is to
        # emphasize the fact that we want it to return nil. also, so that
        # we don't accidentally run a Runnable while inspecting it
        nil 
      end
    end
    include Aliases
    
    # Integer math is now floating-point math
    # hashtag gitonmahlevel
    class ::Integer
      alias_method :old_div, :/
      
      def /(other)
        self.to_f / other.to_f
      end
    end
  
    module ExecutableBinaries
      # Executable files
      COMMANDS = {}
      PRIORITY_METHODS = []
      def path_for_exec(name)
        # poor man's caching
        return COMMANDS[name] if COMMANDS[name]
      
        ENV['PATH'].split(':').each do |p|
          if File.exist? File.join(p, name.to_s)
            COMMANDS[name] = File.join(p, name.to_s)
            return COMMANDS[name]
          end
        end
      
        false
      end
      
      def method_missing(name, *args, &block)
        if meth = lookup(name, *args, &block)
          return meth
        end
      
        # If we made it this far, there is no executable to be had. Super it up.
        super
      end
  
      def raw_exec(path, *args)
        Executable.new path, *args
      end
      alias_method :here, :raw_exec
      alias_method :h, :raw_exec

      # This allows for `__/'disco` as `./disco`
      def __; '.'; end

      def lookup(name, *args, &block)
        if PRIORITY_METHODS.include? name
          return StringMethod.new(name, *args, &block)
        end
  
        if path_for_exec(name)
          return Executable.new(path_for_exec(name), *args)
        end
  
        if "".public_methods(false).include? name
          return StringMethod.new(name, *args, &block)
        end

        nil
      end
    end
    include ExecutableBinaries
  
    pre_process do |val|
      proper_string val
      # if there is an unclosed string, close it and run it again.
      # smart compilers are bad... but this ain't a compiler
      #
      # option: make it ask for confirmation first
      # settable in chitinrc, perjaps?
      if (e = syntax_error_for(val)) &&
         e.message =~ /unterminated string meets end of file/
    
        if syntax_error_for(val + '\'')
          unless syntax_error_for(val + '"')
            val << '"'
          end
        else
          val << '\''
        end
    
      end
    
      val
    end
    
    # You can use error classes as a name and if the error comes up,
    # block of code will be run.
    # 
    # post_process SyntaxError do |e, val|
    #   # sample
    # end
    
    post_process :color do |val|
      Wirble::Colorize.colorize val
    end
  end 
end

