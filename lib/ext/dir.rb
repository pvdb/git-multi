class Dir
  def git_repos(subdir = '*')
    Dir.glob(File.join(path, subdir, '*', '.git')).map { |path_to_git_dir|
      path_to_git_repo = File.dirname(path_to_git_dir) # without "/.git"
      repo_name = path_to_git_repo[%r{[^/]+/[^/]+\z}]  # e.g. "pvdb/git-multi"
      def repo_name.full_name() self; end # rubocop:disable Style/SingleLineMethods
      repo_name
    }
  end
end
