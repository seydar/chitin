def need(file)
  require(File.dirname(File.expand_path(__FILE__)) + '/' + file)
end

need 'chitin/version'
need 'chitin/support'
need 'chitin/file'

Dir[File.dirname(File.expand_path(__FILE__)) + '/chitin/core_ext/*'].each do |f|
  require f
end

need 'chitin/commands/runnable'
Dir[File.dirname(File.expand_path(__FILE__)) + '/chitin/commands/*'].each do |f|
  require f
end

need 'chitin/tools/string_methods'

need 'chitin/sandbox'
need 'chitin/session'

require 'date'
require 'fileutils'
require 'pp'

