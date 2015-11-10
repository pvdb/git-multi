module Git
  module Hub

    module_function

    def client
      @client ||= Git::Meta.send(:client)
    end

    # FIXME update login as part of `--refresh`

    def login
      @login ||= begin
        client.user.login
      rescue Octokit::Unauthorized, Faraday::ConnectionFailed
        nil
      end
    end

    # FIXME update orgs as part of `--refresh`

    def orgs
      @orgs ||= begin
        client.organizations.map(&:login)
      rescue Octokit::Unauthorized, Faraday::ConnectionFailed
        []
      end
    end

  end
end
