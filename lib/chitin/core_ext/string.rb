require 'wirble'

class String
  def -@
    "-#{self}"
  end

  def nothing     ; Wirble::Colorize.colorize_string self, :nothing     ; end
  def black       ; Wirble::Colorize.colorize_string self, :black       ; end
  def red         ; Wirble::Colorize.colorize_string self, :red         ; end
  def green       ; Wirble::Colorize.colorize_string self, :green       ; end
  def brown       ; Wirble::Colorize.colorize_string self, :brown       ; end
  def blue        ; Wirble::Colorize.colorize_string self, :blue        ; end
  def cyan        ; Wirble::Colorize.colorize_string self, :cyan        ; end
  def purple      ; Wirble::Colorize.colorize_string self, :purple      ; end
  def light_gray  ; Wirble::Colorize.colorize_string self, :light_gray  ; end
  def dark_gray   ; Wirble::Colorize.colorize_string self, :dark_gray   ; end
  def light_red   ; Wirble::Colorize.colorize_string self, :light_red   ; end
  def light_green ; Wirble::Colorize.colorize_string self, :light_green ; end
  def yellow      ; Wirble::Colorize.colorize_string self, :yellow      ; end
  def light_blue  ; Wirble::Colorize.colorize_string self, :light_blue  ; end
  def light_cyan  ; Wirble::Colorize.colorize_string self, :light_cyan  ; end
  def light_purple; Wirble::Colorize.colorize_string self, :light_purple; end
  def white       ; Wirble::Colorize.colorize_string self, :white       ; end

  def map_lines(&block)
    split("\n").map(&block)
  end

  # Make an executable out of File.join(self, other)
  def /(other)
    Chitin::Executable.new File.join(self, other.to_s)
  end

  def >>(other)
    case other
    when Chitin::FileObject
      other.to_a.each do |fo|
        next if fo.directory?

        File.open(fo.to_s, 'a') {|f| f.puts self }
      end
    when String
      File.open(other, 'a') {|f| f.puts self }
    else
      raise "Unknown piping type: #{other.class}"
    end
  
    other
  end

  def >(other)
    case other
    when Chitin::FileObject
      other.to_a.each do |fo|
        next if fo.directory?

        File.open(fo.to_s, 'w') {|f| f.puts self }
      end
    when String
      File.open(other, 'w') {|f| f.puts self }
    else
      raise "Unknown piping type: #{other.class}"
    end
  
    other
  end

  def |(other)
    NULLIN > L { self } | other
  end
end

