require 'coolline'

class Coolline
  def bind(key, &action)
    @handlers.unshift Handler.new(key, &action)
  end

  # This is to deal wtih adding closing quotes on completions.
  # It assumes that the completion proc will automatically place
  # a leading quote on the line.
  def complete
    return if word_boundary? line[pos - 1]

    completions = @completion_proc.call(self)

    if completions.empty?
      menu.string = ""
    elsif completions.size == 1
      menu.string = ""
      word = completions.first

      # don't close quotes on directories
      if word[-1, 1] != '/'
        word += word[0, 1] # because there's a quote from when we expand the options
      end

      self.completed_word = word
    else
      menu.list = completions
      self.completed_word = common_beginning(completions)
    end
  end

  alias_method :old_word_beginning_before, :word_beginning_before

  # This is to make word completion complete entire unquoted strings.
  # Very useful since Ruby doesn't have space escapes like in Bash.
  def word_beginning_before(pos)
    # if the line is an uncompleted string, make it the whole string
    # else, do the normal shit
    if incomplete_string line[0..pos]
      point = line[0..pos].reverse.index incomplete_string(line[0..pos])
      line[0..pos].size - point - 1
    else
      old_word_beginning_before(pos)
    end
  end

  # In tests, this reads the first character of buffered input.
  # In practice, this does not do anything differently than `@input.getch`
  # C'est la vie.
  def read_char
    @input.raw { @input.getc }
  end

  # This is here because the line:
  #   until (char = @input.getch) == "\r"
  # was replaced with:
  #   until (char = read_char) == "\r"
  # because I'm trying and failing to fix it so that Coolline
  # will read buffered characters from STDIN. For example:
  #   def test; sleep 2; STDIN.getch; end
  # if you run that and type a bunch of characters, it will only
  # return the first character you typed AFTER STDIN.getch got a chance
  # to run. Ideally, with `read_char` it will read the first character that
  # you typed regardless.
  #
  # Also, @history_moved appears to be a useless variable.
  def readline(prompt = ">> ")
    @prompt = prompt

    @history.delete_empty

    @line        = ""
    @pos         = 0
    @accumulator = nil

    @history_moved = false

    @should_exit = false

    reset_line
    print @prompt

    @history.index = @history.size - 1
    @history << @line

    until (char = read_char) == "\r"
      @menu.erase

      handle(char)
      return if @should_exit

      if @history_moved
        @history_moved = false
      end

      render
    end

    @menu.erase

    print "\n"

    @history[-1] = @line if @history.size != 0
    @history.index = @history.size

    @history.save_line

    @line
  end
end

