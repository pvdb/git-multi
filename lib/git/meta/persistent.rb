begin
  require 'net/http/persistent'
  Octokit.middleware.swap(
    Faraday::Adapter::NetHttp,          # default Faraday adapter
    Faraday::Adapter::NetHttpPersistent # experimental Faraday adapter
  )
rescue LoadError
  # NOOP  -  `Net::HTTP::Persistent` is optional, so
  # if the gem isn't installed, then we run with the
  # default `Net::HTTP` Faraday adapter;  if however
  # the gem is installed then we make Faraday use it
  # to benefit from persistent HTTP connections
end
