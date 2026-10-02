require 'active_scaffold_config_list/engine'
require 'active_scaffold_config_list/version'

module ActiveScaffold
  module Actions
    ActiveScaffold.autoload_subdir('actions', self, File.dirname(__FILE__))
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self, File.dirname(__FILE__))
  end

  module DataStructures
    ActiveScaffold.autoload_subdir('data_structures', self, File.dirname(__FILE__))
  end

  module Helpers
    ActiveScaffold.autoload_subdir('helpers', self, File.dirname(__FILE__))
  end
end
ActiveSupport.run_load_hooks(:active_scaffold_config_list)
{
  config_list_views: :div,
  config_list_view_selected: :div,
  config_list_views_list: :ul,
  config_list_view_item: :li,
  config_list_view_label: :label,
  config_list_sorting: :ol,
  config_list_sorting_item: :li,
  config_list_view_rename: :label,
  config_list_view_global: :label
}.each { |name, tag| ActiveScaffold.set_element_tag(name, tag) }
ActiveScaffold.stylesheets << 'active_scaffold_config_list'
ActiveScaffold.javascripts << 'active_scaffold_config_list'
