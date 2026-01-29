module ActiveScaffold::Actions
  module ConfigList
    
    def self.included(base)
      base.before_action :set_default_sorting, :change_view, only: [:index]
      base.before_action :config_list_authorized_filter, only: [:show_config_list, :config_list]
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

    def change_view
      active_scaffold_config.list.refresh_with_header = true if params[:config_list_view]
    end

    def config_list_formats
      [:html, :js]
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
      if (params['sort_direction'] && params['sort_direction'] == 'reset') || (active_scaffold_config.list.user['sort'].blank? && params['sort'].blank?)
        active_scaffold_config.list.user.sorting.set *config_list_sorting if config_list_sorting
      end
    end

    def do_config_list
      config_list = params.delete :config_list
      case config_list
      when String
        delete_config_list_params(params.delete(:config_list_view).presence)
      when Array
        save_config_list_params(config_list, config_list_sorting_params, params.delete(:config_list_view_name).presence, params.delete(:config_list_old_view_name))
      end
    end
    
    def config_list_sorting_params
      sorting_params = params.delete(:config_list_sorting)
      if sorting_params
        sorting_params = sorting_params.values.select{ |c,d| c.present? && d.present? }
        sorting_params if sorting_params.present?
      end
    end

    def config_list_session_storage_method
      @config_list_session_storage_method ||=
        if respond_to?(:custom_config_list_session_storage)
          :custom_config_list_session_storage
        else
          :active_scaffold_session_storage
        end
    end

    def config_list_session_storage
      send(config_list_session_storage_method)
    end

    def config_list_session_storage_key
      active_scaffold_session_storage_key
    end

    def config_list_controller_name
      controller_name
    end

    def active_scaffold_current_user
      @active_scaffold_current_user ||= send(self.class.active_scaffold_config.class.security.current_user_method)
    end

    def delete_config_list_params(view_name)
      record = config_list_record(view_name)
      if record
        if record.destroy && view_name.present?
          config_list_record(reload: true)
          return
        end
      else
        config_list_session_storage['config_list'] = nil
        config_list_session_storage['config_list_sorting'] = nil
      end
      active_scaffold_config.list.user['sort'] = nil
      @config_list_params = nil
      @config_list_sorting = nil
    end

    def save_config_list_params(config_list, config_list_sorting, view_name, old_view_name)
      if view_name.present?
        assign = {view_name: view_name}
        assign[:slug] = config_list_slug(view_name, params.delete(:global_view).present?) if active_scaffold_config.config_list.global_views
      end
      record = config_list_record(old_view_name || assign&.dig(:slug) || view_name, assign: assign)

      if record
        record.config_list = config_list.select(&:present?).join(',')
        record.config_list_sorting = config_list_sorting if record.respond_to? :config_list_sorting
        params[:config_list_view] = assign&.dig(:slug) || view_name if record.save
      else
        config_list_session_storage['config_list'] = config_list.map(&:to_sym)
        config_list_session_storage['config_list_sorting'] = config_list_sorting
      end
      @config_list_params = config_list.map(&:to_sym)
      @config_list_sorting = config_list_sorting
    end

    def objects_for_etag
      # only override when list_columns is called, so 
      if @list_columns && config_list_record
        @last_modified = [@last_modified, config_list_record.updated_at].compact.max if config_list_record.respond_to? :updated_at
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

    def config_list_record(view_name = params[:config_list_view], reload: false, assign: nil)
      return @config_list_record if !reload && defined?(@config_list_record)
      @config_list_record =
        if active_scaffold_config.config_list.save_to_user && active_scaffold_current_user
          if view_name.present?
            options = {attributes: assign}
            options[active_scaffold_config.config_list.global_views ? :slug : :view_name] = view_name
          end
          active_scaffold_current_user.send(
            active_scaffold_config.config_list.save_to_user,
            config_list_session_storage_key,
            config_list_controller_name,
            **options
          )
        end
    end

    def find_view_name(slug)
      return unless slug.present?

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

    def config_list_named_views
      @config_list_named_views ||=
        active_scaffold_current_user.send(
          active_scaffold_config.config_list.named_views_method,
          config_list_session_storage_key,
          config_list_controller_name
        ).compact
    end

    def config_list_params
      unless defined? @config_list_params
        @config_list_params =
          if config_list_record
            params = config_list_record.config_list
            params.split(',').map(&:to_sym) if params
          else
            config_list_session_storage['config_list']
          end
      end
      @config_list_params || config_list_default_columns
    end

    def config_list_default_columns
      active_scaffold_config.config_list.default_columns
    end

    def config_list_sorting
      unless defined? @config_list_sorting
        @config_list_sorting =
          if config_list_record
            config_list_record.config_list_sorting if config_list_record.respond_to? :config_list_sorting
          else
            config_list_session_storage['config_list_sorting']
          end
      end
      @config_list_sorting
    end

    def list_columns
      @list_columns ||= named_view_columns || begin
        columns = super
        if config_list_params.present?
          config_list = config_list_params.each.with_index.to_h
          columns.select { |column| config_list.include? column.name }.
            sort { |x, y| config_list[x.name] <=> config_list[y.name] }
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
      return unless params[:config_list_view].present?

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
