require 'stringio'

# The hard part is to not confuse interface with implementation. Tough because
# this relies almost entirely on the interface.
# Possibly reopen STDOUT so that it writes to two, instead of just redefining
# puts/print?
class Replay
  attr_reader :path
  attr_reader :session

  def initialize(path, session)
    @path = path
    @session = session
  end

  def start!
    session.out = MultiIO.new STDOUT, StringIO.new
  end

  def end!
    multi = session.out
    session.out = STDOUT
    stringio = multi.ios[1]
    @text = stringio.read
  end

  def to_s
    @text
  end

end

module Builtins
  
  def record(path="replay.#{DateTime.now.to_s}")
    @__record__ = Replay.new path, SESSION
    @__record__.start!
  end

  def stop
    @__record__.end!
    @__record__
  end
end

