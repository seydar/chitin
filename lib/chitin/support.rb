def proper_string(val)
  # if there is an unclosed string, close it and run it again.
  # smart compilers are bad... but this ain't a compiler
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

# Is this an incomplete string?
# If so, return the string character that it uses.
# Else return false.
def incomplete_string(string)
  return '"' unless syntax_error_for(string + '"')
  return "'" unless syntax_error_for(string + '\'')
  return false
end

# If the code is syntactically correct, return nil.
# Else, return the error.
def syntax_error_for(code) 
  eval "return nil\n#{code}" 
rescue SyntaxError => e
  e
end 

def shellsplit_keep_quotes(line)
  words = []
  field = ''
  line.scan(/\G\s*(?>([^\s\\\'\"]+)|('[^\']*')|("(?:[^\"\\]|\\.)*")|(\\.?)|(\S))(\s|\z)?/m) do
    |word, sq, dq, esc, garbage, sep|
    raise ArgumentError, "Unmatched double quote: #{line.inspect}" if garbage
    field << (word || sq || (dq || esc).gsub(/\\(.)/, '\\1'))
    if sep
      words << field
      field = ''
    end
  end
  words
end

