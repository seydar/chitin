def string_method(name)
  Chitin::Builtins::PRIORITY_METHODS << name.to_sym
end

string_method :gsub
string_method :split
string_method :size
string_method :pack
string_method :unpack

