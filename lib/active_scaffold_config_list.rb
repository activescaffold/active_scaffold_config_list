require 'active_scaffold_config_list/engine'
require 'active_scaffold_config_list/version'

module ActiveScaffoldConfigList
end

module ActiveScaffold
  module Actions
    ActiveScaffold.autoload_subdir('actions', self, File.dirname(__FILE__))
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self, File.dirname(__FILE__))
  end
end
