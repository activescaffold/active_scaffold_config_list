# frozen_string_literal: true

require_relative 'config_list/persistence'

module ActiveScaffold::Actions
  module ConfigList
    include ActiveScaffold::Actions::ConfigListPersistence

    def self.included(base)
      base.before_action :set_default_view, :set_default_sorting, :change_view, only: [:index]
      base.before_action :config_list_authorized_filter, only: %i[show_config_list config_list]
      base.helper_method :config_list_params, :config_list_sorting, :config_list_named_views
    end

    def show_config_list
      config_list_record
      @config_list_view_name = find_view_name(params[:config_list_view])
      if @config_list_view_name.present?
        @global_view = config_list_slug(@config_list_view_name, true) == params[:config_list_view]
      end
      respond_to_action(:show_config_list, config_list_formats)
    end

    def config_list
      do_config_list
      respond_to_action(:config_list, config_list_formats)
    end

    protected

    def set_default_view
      return unless params[:config_list_view].nil?

      default_view = active_scaffold_config.config_list.default_view
      params[:config_list_view] = default_view.to_s if default_view.present?
    end

    def change_view
      active_scaffold_config.list.refresh_with_header = true if params[:config_list_view]
    end

    def config_list_formats
      %i[html js]
    end

    def show_config_list_respond_to_html
      render(action: 'show_config_list_form', layout: true)
    end

    def show_config_list_respond_to_js
      render(partial: 'show_config_list_form', layout: false)
    end

    def config_list_respond_to_html
      redirect_to action: :index, config_list_view: params[:config_list_view_name]
    end

    def do_refresh_list
      set_default_sorting
      super
    end

    def config_list_respond_to_js
      do_refresh_list
      active_scaffold_config.list.refresh_with_header = true
      list_url = params_for(action: :index, config_list_view: params[:config_list_view].presence)
      render partial: 'refresh_list', locals: {history_url: url_for(list_url)}, formats: [:js]
    end

    def set_default_sorting
      reset_sorting = params['sort_direction'] == 'reset'
      missing_sorting = active_scaffold_config.list.user['sort'].blank? && params['sort'].blank?
      if (reset_sorting || missing_sorting) && config_list_sorting
        active_scaffold_config.list.user.sorting.set(*config_list_sorting)
      end
    end

    def do_config_list
      config_list = params.delete :config_list
      case config_list
      when String
        delete_config_list_params(params.delete(:config_list_view).presence)
      when Array
        save_config_list_params(
          config_list,
          config_list_sorting_params,
          params.delete(:config_list_view_name).presence,
          params.delete(:config_list_old_view_name)
        )
      end
    end

    def config_list_sorting_params
      sorting_params = params.delete(:config_list_sorting)
      return unless sorting_params

      sorting_params = sorting_params.values.select { |c, d| c.present? && d.present? }
      sorting_params.presence
    end

    def objects_for_etag
      # only override when list_columns is called, so
      if @list_columns && config_list_record
        if config_list_record.respond_to? :updated_at
          @last_modified = [@last_modified, config_list_record.updated_at].compact.max
        end
        objects = super
        if objects.is_a? Hash
          objects.merge(etag: [objects[:etag], config_list_record])
        else
          [objects, config_list_record]
        end
      else
        super
      end
    end

    def find_view_name(slug)
      return if slug.blank?

      config_list_named_views.find do |view_name, view_slug|
        break view_name if slug == (view_slug || view_name)
      end
    end

    def config_list_slug(view_name, global_view)
      return view_name unless active_scaffold_config.config_list.global_views

      if ActiveScaffold::Config::ConfigList.slug_builder
        send(ActiveScaffold::Config::ConfigList.slug_builder, view_name, global_view)
      elsif global_view
        "global-#{view_name}"
      else
        "user-#{view_name}"
      end
    end

    def config_list_default_columns
      active_scaffold_config.config_list.default_columns
    end

    def list_columns
      @list_columns ||= named_view_columns || begin
        columns = super
        if config_list_params.present?
          config_list = config_list_params.each.with_index.to_h
          columns.select { |column| config_list.include? column.name }
            .sort { |x, y| config_list[x.name] <=> config_list[y.name] }
        else
          columns
        end
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def config_list_authorized?
      named_view.nil? && authorized_for?(action: :read)
    end

    def named_view
      return @named_view if params[:config_list_view].blank?

      @named_view ||= active_scaffold_config.config_list.named_views.find { |v| v.name == params[:config_list_view] }
    end

    def named_view_columns
      return unless named_view

      raise ActiveScaffold::ActionNotAllowed if named_view.security_method && !send(named_view.security_method)

      named_view.columns.visible_columns(flatten: true)
    end

    def config_list_authorized_filter
      raise ActiveScaffold::ActionNotAllowed unless config_list_authorized?
    end
  end
end
