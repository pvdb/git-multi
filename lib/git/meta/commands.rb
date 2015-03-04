module Git
  module Meta
    module Commands

      module_function

      def version
        puts Git::Meta::VERSION
      end

      def user
        puts Git::Meta::USER
      end

      def token
        puts Git::Meta::TOKEN
      end

    end
  end
end