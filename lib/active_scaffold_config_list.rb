require 'active_scaffold_config_list/engine'
require 'active_scaffold_config_list/version'

module ActiveScaffold
  module Actions
    ActiveScaffold.autoload_subdir('actions', self, File.dirname(__FILE__))
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self, File.dirname(__FILE__))
  end

  module Helpers
    ActiveScaffold.autoload_subdir('helpers', self, File.dirname(__FILE__))
  end
end
ActiveSupport.run_load_hooks(:active_scaffold_config_list)