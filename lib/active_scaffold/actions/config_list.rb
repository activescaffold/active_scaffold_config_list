module ActiveScaffold::Actions
  module ConfigList
    
    def self.included(base)
      base.before_action :store_config_list_params, :set_default_sorting, only: [:index]
      base.helper_method :config_list_params, :config_list_sorting, :config_list_named_views
    end

    def show_config_list
      respond_to do |type|
        type.html do
          render(action: 'show_config_list_form', layout: true)
        end
        type.js do
          render(partial: 'show_config_list_form', layout: false)
        end
      end
    end
    
    protected
    
    def set_default_sorting
      if (params['sort_direction'] && params['sort_direction'] == 'reset') || (active_scaffold_config.list.user['sort'].blank? && params['sort'].blank?)
        active_scaffold_config.list.user.sorting.set *config_list_sorting if config_list_sorting
      end
    end

    def store_config_list_params
      if params[:config_list]
        config_list = params.delete :config_list
        case config_list
        when String
          delete_config_list_params
        when Array
          save_config_list_params(config_list, config_list_sorting_params, params.delete(:config_list_view_name).presence, params.delete(:config_list_old_view_name))
        end
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

    def delete_config_list_params
      if active_scaffold_config.config_list.save_to_user && active_scaffold_current_user
        active_scaffold_current_user.send(active_scaffold_config.config_list.save_to_user, config_list_session_storage_key, config_list_controller_name).destroy
      else
        config_list_session_storage['config_list'] = nil
        config_list_session_storage['config_list_sorting'] = nil
      end
      active_scaffold_config.list.user['sort'] = nil
      @config_list_params = nil
      @config_list_sorting = nil
    end

    def save_config_list_params(config_list, config_list_sorting, view_name, old_view_name)
      record = config_list_record(old_view_name || view_name)
      record = config_list_record(view_name, reload: true) if old_view_name.present? && record&.new_record?
      if record
        record.view_name = view_name
        record.config_list = config_list.join(',')
        record.config_list_sorting = config_list_sorting if record.respond_to? :config_list_sorting
        record.save
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

    def config_list_record(view_name = nil, reload: false)
      return @config_list_record if !reload && defined?(@config_list_record)
      view_name ||= params[:config_list_view]
      @config_list_record =
        if active_scaffold_config.config_list.save_to_user && active_scaffold_current_user
          args = [config_list_session_storage_key, config_list_controller_name]
          args << view_name if view_name.present?
          active_scaffold_current_user.send(active_scaffold_config.config_list.save_to_user, *args)
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
      @list_columns ||= begin
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
      authorized_for?(action: :read)
    end
  end
end
