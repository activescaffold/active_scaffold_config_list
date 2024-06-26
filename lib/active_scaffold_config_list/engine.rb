module ActiveScaffoldConfigList
  class Engine < ::Rails::Engine
    initializer 'active_scaffold_config_list.routes' do
      ActiveSupport.on_load :active_scaffold_routing do
        self::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection][:show_config_list] = :get
      end
    end
  end
end
