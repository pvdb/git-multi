class Dir
  def git_repos(subdir = '*')
    Dir.glob(File.join(self.path, subdir, '*', '.git')).map { |path_to_git_dir|
      path_to_git_repo = File.dirname(path_to_git_dir) # without "/.git"
      repo_name = path_to_git_repo[/[^\/]+\/[^\/]+\z/] # e.g. "pvdb/git-multi"
      def repo_name.full_name() self ; end             # awesome duck-typing!
      repo_name
    }
  end
end
