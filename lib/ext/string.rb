# rubocop:disable Layout/EmptyLineBetweenDefs

class String

  def colorize(color_code) "\e[#{color_code}m#{self}\e[0m"; end

  def bold()   colorize('1'); end
  def invert() colorize('7'); end

  def red()   colorize('31'); end
  def blue()  colorize('34'); end
  def green() colorize('32'); end

  def undent() gsub(/^.{#{slice(/^ +/).length}}/, ''); end

end

# rubocop:enable Layout/EmptyLineBetweenDefs
