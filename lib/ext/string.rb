class String
  def colorize(color_code) "\e[#{color_code}m#{self}\e[0m" ; end
  def bold()   colorize('1') ; end
  def invert() colorize('7') ; end
  def undent() gsub(/^.{#{slice(/^ +/).length}}/, '') ; end
end
