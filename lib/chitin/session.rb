require 'coderay'

module Chitin
  class Session
    attr_accessor :sandbox
    attr_accessor :out
  
    attr_reader :config
    attr_reader :editor
  
    def initialize(config=nil)
      @config  = config
      @out     = STDOUT
      @sandbox = Sandbox.new # give it its own private space to work
      (class << @sandbox; self; end).send :include, @config # include the config and builtins

      @editor  = Coolline.new do |c|
        # Remove the default of '-' and add support for strings
        # starting after parentheses.
        c.word_boundaries = [' ', "\t", "(", ")", '[', ']']
        c.history_file    = File.join ENV['HOME'], '.chitin_history'

        # Make sure we don't kill the shell accidentally when we're trying to
        # kill a file. That's what the default does, so we're overriding that
        # here.
        c.bind(?\C-c) {}

        c.transform_proc = proc do
          CodeRay.scan(c.line, :ruby).term
        end
  
        c.completion_proc = Proc.new do
          line = c.completed_word
  
          # expand ~ to homedir
          if line.start_with? '~'
            line = ENV['HOME'] + line[1..-1]
          end
  
          # if there's a quote, remove it. we'll add it back in later, but it ruins
          # searching so we need it removed for now.
          unquoted_line = ['"', '\''].include?(line[0, 1]) ? line[1..-1] : line
  
          Dir[unquoted_line + '*'].map do |w|
            slash_it = File.directory?(w) and line[-1] != '/' and w[-1] != '/'
  
            "\"#{w}#{slash_it ? '/' : ''}"
          end
        end
      end

      if @sandbox.completion_proc
        @editor.completion_proc = @sandbox.completion_proc
      end
    end
  
    # Read
    # Evaluate
    # Print (display)
    # Loop
    def start
      while (val = read)
        next if val.empty?
  
        begin
          res = evaluate val
          display res unless val.lstrip[0, 1] == '#'
        rescue StandardError, ScriptError, Interrupt => e
          @config.post_processing[e.class].call e, val
  
          print e.backtrace.first, ': '
          puts "#{e.message} (#{e.class})"
          e.backtrace[1..-1].each {|l| puts "\t#{l}" }
          nil
        end
  
      end
    end
  
    # THIS METHOD WILL POSSIBLY RETURN NIL!!!!!
    # So it can return a string or nil. Remember that, folks.
    def read
      # find out the column (1-indexed) that will next be printed
      # if it's NOT 1, then something was printed, and we want to insert
      # a newline
      a = nil
      STDIN.raw do
        print "\e[6n"
        a = STDIN.gets 'R'
      end

      if a.chomp('R').split(';').last != '1'
        puts
        puts "(no trailing newline)"
      end

      inp = @editor.readline @sandbox.prompt
  
  
      inp ? inp.chomp : nil # return nil so that the while loop in #start can end
    end
  
    # we need to save the frame or something i think. could use fibers
    # to make the whole thing a generator so that original frame would be saved.
    # why did i write those lines. that makes no sense.
    # AH now i remember. we need to save a frame and use that frame as a sandbox.
    def evaluate(val)
      val.strip!
      @config.pre_processing[:default].each {|p| val = p.call val }
  
      @sandbox.evaluate val
    end
  
    def returning_ruby?(res)
      # We have to use #stat here because reopened pipes retain the file
      # descriptor of the original pipe. Example:
      #   r, w = IO.pipe; r.reopen STDIN; r == STDIN # => false
      # Thus, we have to use #stat (or, more lamely, #inspect).
      return true unless Runnable === res

      res[:returning] == :ruby &&
        (res[:out] == nil ||
        res[:out].stat == STDOUT.stat)
    end

    def all_not_ruby?(res)
      if Array === res
         !res.empty? && res.map {|r| not returning_ruby? r }.all?
      else
        not returning_ruby? res
      end
    end
    alias_method :all_shell?, :all_not_ruby?
  
    def display(res)
      # The reason that this is here instead of in #evaluate is that
      # pipes could, in fact, have NO display output, but that isn't for
      # #evaluate to decide: rather, it is for #display
      if all_shell? res
        res = [res] unless Array === res
  
        res.each do |res|
          res[:run]
          res[:wait] unless res[:bg]
        end
  
      else # else it's a standard ruby type (or a pipe returning as such)
  
        if Pipe === res || StringMethod === res
          val = res[:raw_run]
        else
          val = res
        end

        # if the input is ruby, then this is redundant
        # if the input is a pipe that returns ruby,
        # then this is needed because while the expression
        # returns a pipe, when we run it it returns a ruby
        # value. we want to remember the ruby value.
        @sandbox.previous = val
  
        txt = @config.post_processing[:color].call val.inspect
        puts " => #{txt}"
      end
  
      # Run all the post_processing stuff
      # Not sure where I should really put this or what arguments it should have
      @config.post_processing[:default].each {|b| b.call }
    end
  
    def puts(*args)
      @out.puts *args
    end
  
    def print(*args)
      @out.print *args
    end
  end
end
