require 'active_scaffold_config_list/config_listable'
module ActiveScaffoldConfigList
  class Engine < ::Rails::Engine
    initializer 'active_scaffold_config_list.routes' do
      ActiveSupport.on_load :active_scaffold_routing do
        self::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection][:show_config_list] = :get
        self::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection][:config_list] = :post
      end
    end

    initializer 'active_scaffold_config_list.action_view' do
      ActiveSupport.on_load :action_view do
        ActionView::Base.send :include, ActiveScaffold::Helpers::ConfigListHelpers
      end
    end

    initializer 'active_scaffold_config_list.active_record' do |app|
      ActiveSupport.on_load :active_record do
        include ActiveScaffoldConfigList::ConfigListable
      end
    end
  end
end
