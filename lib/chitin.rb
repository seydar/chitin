LOCAL_CHITIN_SRC = File.dirname(File.expand_path(__FILE__))
def need(file)
  require(LOCAL_CHITIN_SRC + '/' + file)
end

require 'date'
require 'fileutils'
require 'pp'

need 'chitin/version'
need 'chitin/support'
need 'chitin/file'

need 'chitin/core_ext/array.rb'
need 'chitin/core_ext/class.rb'
need 'chitin/core_ext/coolline.rb'
need 'chitin/core_ext/io.rb'
need 'chitin/core_ext/kernel.rb'
need 'chitin/core_ext/object.rb'
need 'chitin/core_ext/string.rb'
need 'chitin/core_ext/symbol.rb'

need 'chitin/commands/runnable'
need 'chitin/commands/builtins.rb'
need 'chitin/commands/executable.rb'
need 'chitin/commands/pipe.rb'
need 'chitin/commands/ruby.rb'

need 'chitin/tools/string_methods'

need 'chitin/sandbox'
need 'chitin/session'

