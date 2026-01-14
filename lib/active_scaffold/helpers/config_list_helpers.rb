module ActiveScaffold
  module Helpers
    module ConfigListHelpers
      def config_list_sorting?
        true
      end

      def config_list_columns?
        true
      end

      def config_list_save_named_views?
        active_scaffold_config.config_list.save_named_views
      end

      def config_list_columns
        columns =
          if config_list_params.is_a?(Array)
            config_list = config_list_params
            list_columns.concat active_scaffold_config.list.columns.visible_columns.select { |column| config_list.exclude? column.name }
          else
            list_columns
          end
        columns.map { |c| [column_heading_label(c), c.name] }
      end
    end
  end
end