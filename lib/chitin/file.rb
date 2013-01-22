module Chitin
  class FSObject
    include Enumerable

    attr_accessor :path
    attr_accessor :search
  
    # The choice to not have File.expand_path here is explicitly done.
    # Relativity is up to the user.
    # Also it got really annoying seeing the same prefix over and over
    # and over again on lists of files.
    def initialize(path, opts={})
      @path = path
      @search = proc { path }
      @unknown = opts[:unknown]
    end

    def unknown_type?
      @unknown
    end

    def files
      return @files if @files
      files = Dir[search.call]
      @files = files.inject({}) do |h, f|
        f = f[2..-1] if f.start_with? './'
        h[f] = if File.directory? f
                 D f
               elsif File.file? f
                 F f
               elsif File.symlink? f
                 S f
               else
                 FSObject.new f, :unknown => true
               end
  
        h
      end
    end

    def each(&block)
      files.values.each &block
    end

    def to_a
      files.values
    end

    def size
      files.size
    end

    def lstat
      File.lstat @path
    end
  
    def to_s
      path
    end

    def symlink?
      false
    end
  end

  class FileObject < FSObject
    def readable?(force=false)
      @readable = force ? File.readable(path) : @readable
    end
  
    def writeable?(force=false)
      @writeable = force ? File.writeable?(path) : @writeable
    end
  
    def exists?
      File.exists? path
    end
  
    def open(permissions, &block)
      File.open path, permissions do |f|
        block.call f
      end
    end
 
    def delete
      File.safe_unlink @path
    end
  
    def executable?(force=false)
      @executable = force ? File.executable?(path) : @executable
    end
  
    def inspect
      "#<Chitin::FileObject #{path.inspect}>"
    end
  end

  class Symlink < FileObject
    def symlink?
      true
    end

    def inspect
      "#<Chitin::Symlink #{path}>"
    end
  end

  class Directory < FSObject
    def initialize(path, opts={})
      super
      @search = proc { File.join self.path, '*' }
    end

    def down
      @path = File.join path, '**'
      @files = nil
      self
    end

    # Get a specific level down
    def level(n=1)
      n.times { @path = File.join self.path, '*' }
      @files = nil
      self
    end
 
    def delete
      # this is probably unwise...
      File.rm_rf path
    end

    def inspect
      "#<Chitin::Directory #{path.inspect}>"
    end
  end
end

module Kernel
  def D(path); Chitin::Directory.new path; end
  def F(path); Chitin::FileObject.new path; end
  def S(path); Chitin::Symlink.new path; end

  alias_method :d, :D
  alias_method :f, :F
  alias_method :s, :S

  NULLIN = NULLOUT = NULLERR = File.open File::NULL
end

