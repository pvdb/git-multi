begin
  require 'terminal-notifier'
rescue LoadError
  # NOOP - "TerminalNotifier" is optional
  # will only be used if it is installed!
end

module Git
  module Meta

    def notify(message, options = {}, verbose = false)
      # print the given message to STDERR, if the
      # script is running with "--verbose" option
      subtitle = options[:subtitle]
      warn(subtitle ? "#{subtitle}: #{message}" : message) if $VERBOSE
      # send a given message to the Mac OS X Notification Center
      # but only if the git-meta script is running interactively
      # and if the "terminal-notifier" gem has been installed...
      if Nike.interactive? && defined?(TerminalNotifier)
        options[:title] ||= 'git-meta'
        TerminalNotifier.notify(message, options, verbose)
      end
    end

    module_function :notify

  end
end
