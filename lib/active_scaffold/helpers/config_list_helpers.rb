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
        active_scaffold_config.config_list.named_views_method.present?
      end

      def config_list_named_views?
        return unless active_scaffold_config.actions.include? :config_list
        config_list_save_named_views? || active_scaffold_config.config_list.named_views.present?
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

      def user_named_views
        return [] unless config_list_save_named_views?
        config_list_named_views
      end

      def active_scaffold_named_view_selector
        named_views = user_named_views
        return unless named_views.any?

        named_views.unshift ['Default', '']
        case active_scaffold_config.config_list.named_views_selector
        when :select
          select_tag('config_list_view', options_for_select(named_views, params[:config_list_view]))
        when :radio
          buttons = named_views.map do |(label, name)|
            name ||= label
            content_tag(:label) do
              radio_button_tag('config_list_view', name, name == params[:config_list_view]) + label
            end
          end
          safe_join(buttons)
        end
      end
    end
  end
end