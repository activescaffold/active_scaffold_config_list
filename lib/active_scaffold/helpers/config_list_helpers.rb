# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ConfigListHelpers
      def config_list_sorting?
        true
      end

      def config_list_columns?
        true
      end

      def ignore_param_for_nested?(key)
        super || key == :config_list_view
      end

      def named_view
        controller.send(:named_view) if active_scaffold_config.actions.include?(:config_list)
      end

      def config_list_save_named_views?
        active_scaffold_config.config_list.named_views_method.present?
      end

      def config_list_named_views?
        return false unless active_scaffold_config.actions.include? :config_list

        config_list_save_named_views? || active_scaffold_config.config_list.named_views.present?
      end

      def config_list_global_views?
        return false unless active_scaffold_config.actions.include? :config_list

        config_list_save_named_views? && active_scaffold_config.config_list.global_views
      end

      def config_list_columns
        columns =
          if config_list_params.is_a?(Array)
            config_list = config_list_params
            available_columns = active_scaffold_config.list.columns.visible_columns
            list_columns.concat(available_columns.select { |column| config_list.exclude? column.name })
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

          [view.label, view.name, view.tooltip]
        end
      end

      def config_list_unnamed_view?
        security_method = active_scaffold_config.config_list.unnamed_view_security_method
        security_method.nil? || controller.send(security_method)
      end

      def active_scaffold_named_view_selector
        named_views = user_named_views + named_views_from_config
        return unless named_views.any?

        named_views.unshift [as_(:default_view), ''] if config_list_unnamed_view?
        html = config_list_view_options(named_views, params[:config_list_view].to_s)
        if active_scaffold_config.config_list.named_views_selector == :select
          select_options = as_element_attributes(:config_list_view_select, id: nil)
          html = select_tag('config_list_view', html, select_options)
        end
        html
      end

      def config_list_view_options(named_views, selected)
        case active_scaffold_config.config_list.named_views_selector
        when :links then config_list_view_links(named_views, selected)
        when :select then config_list_view_select_options(named_views, selected)
        when :radio then config_list_view_radio_buttons(named_views, selected)
        end
      end

      private

      def config_list_view_links(named_views, selected)
        url = url_for(params_for(action: :index, config_list_view: '--VIEW--'))
        selected_label = nil
        links = named_views.map do |label, name, tooltip|
          view_name = name || label
          link_options = as_element_attributes(:config_list_view_link, remote: true, title: tooltip)
          link = link_to(label, url.sub('--VIEW--', ERB::Util.unwrapped_html_escape(view_name)), link_options)
          selected_label = label if view_name == selected
          as_element :config_list_view_item, link, class: ('selected' if view_name == selected)
        end
        as_element(:config_list_view_selected, selected_label || as_(:default_view), class: 'selected-view') +
          as_element(:config_list_views_list, safe_join(links), class: 'views')
      end

      def config_list_view_select_options(named_views, selected)
        options = named_views.map do |label, name, tooltip|
          option_attributes = as_element_attributes(:config_list_view_option, title: tooltip).to_h.compact
          [label, name || label, option_attributes]
        end
        options_for_select(options, selected)
      end

      def config_list_view_radio_buttons(named_views, selected)
        buttons = named_views.map do |label, name, tooltip|
          view_name = name || label
          radio_options = as_element_attributes(:config_list_view_radio, id: nil)
          as_element(:config_list_view_label, title: tooltip) do
            radio_button_tag('config_list_view', view_name, view_name == selected, **radio_options.to_h) + label
          end
        end
        safe_join(buttons)
      end
    end
  end
end
