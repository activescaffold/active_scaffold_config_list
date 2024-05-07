module ActiveScaffold
  module Actions
    ActiveScaffold.autoload_subdir('actions', self, File.dirname(__FILE__) + "/..")
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self, File.dirname(__FILE__) + "/..")
  end
end
