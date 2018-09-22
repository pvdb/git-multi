module Kernel
  def interactive?
    STDOUT.tty? && STDERR.tty?
  end
end
