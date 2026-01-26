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

      def named_views_from_config
        active_scaffold_config.config_list.named_views.filter_map do |view|
          next if view.security_method && !controller.send(view.security_method)
          [view.label, view.name]
        end
      end

      def active_scaffold_named_view_selector
        named_views = user_named_views + named_views_from_config
        return unless named_views.any?

        named_views.unshift [as_(:default_view), '']
        html = config_list_view_options(named_views, params[:config_list_view].to_s)
        if active_scaffold_config.config_list.named_views_selector == :select
          html = select_tag('config_list_view', html, id: nil)
        end
        html
      end

      def config_list_view_options(named_views, selected)
        case active_scaffold_config.config_list.named_views_selector
        when :links
          url = url_for(params_for(action: :index, config_list_view: '--VIEW--'))
          view = nil
          links = named_views.map do |(label, name)|
            name ||= label
            link = link_to(label, url.sub('--VIEW--', ERB::Util.unwrapped_html_escape(name)), remote: true)
            view = label if name == selected
            content_tag :li, link, class: ('selected' if name == selected)
          end
          content_tag(:div, view, class: 'selected-view') + content_tag(:ul, safe_join(links), class: 'views')

        when :select
          options_for_select(named_views, selected)

        when :radio
          buttons = named_views.map do |(label, name)|
            name ||= label
            content_tag(:label) do
              radio_button_tag('config_list_view', name, name == selected, id: nil) + label
            end
          end
          safe_join(buttons)
        end
      end
    end
  end
end