ACTIVE_SCAFFOLD_CONFIG_LIST_PLUGIN = true

require 'active_scaffold_config_list'

begin
  ActiveScaffoldAssets.copy_to_public(ActiveScaffoldConfigList.root)
rescue
  raise $! unless Rails.env == 'production'
end