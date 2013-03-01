module ActiveScaffoldConfigList
  class Engine < ::Rails::Engine
    initializer("initialize_active_scaffold_config_list", :after => "initialize_active_scaffold") do
      ActiveSupport.on_load(:action_controller) do
        require "active_scaffold_config_list/config/core.rb"
      end

      ActiveSupport.on_load(:action_view) do
        include ActiveScaffold::Helpers::ConfigListHelpers
      end
    end
  end
end
