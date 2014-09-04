module ActiveScaffold::Actions
  module ConfigList
    
    def self.included(base)
      base.before_filter :store_config_list_params, :set_default_sorting, :only => [:index]
      base.helper_method :config_list_params, :config_list_sorting
      base.extend ClassMethods
    end

    module ClassMethods
      def config_list_session_storage_method
        @config_list_session_storage_method
      end

      def config_list_session_storage_method=(value)
        @config_list_session_storage_method = value
      end
    end

    def show_config_list
      respond_to do |type|
        type.html do
          render(:action => 'show_config_list_form', :layout => true)
        end
        type.js do
          render(:partial => 'show_config_list_form', :layout => false)
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
          save_config_list_params(config_list, config_list_sorting_params)
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
      respond_to?(:custom_config_list_session_storage) ? :custom_config_list_session_storage : :active_scaffold_session_storage
    end

    def config_list_session_storage
      self.class.config_list_session_storage_method = self.config_list_session_storage_method unless self.class.config_list_session_storage_method
      send(self.class.config_list_session_storage_method)
    end

    def delete_config_list_params
      if active_scaffold_config.config_list.save_to_user && current_user = send(active_scaffold_config.class.security.current_user_method)
        current_user.send(active_scaffold_config.config_list.save_to_user, active_scaffold_session_storage_key, controller_name).destroy
      else
        config_list_session_storage['config_list'] = nil
        config_list_session_storage['config_list_sorting'] = nil
      end
      active_scaffold_config.list.user['sort'] = nil
      logger.debug "list #{active_scaffold_config.list.sorting.object_id}"
      @config_list_params = nil
      @config_list_sorting = nil
    end

    def save_config_list_params(config_list, config_list_sorting)
      if active_scaffold_config.config_list.save_to_user && current_user = send(active_scaffold_config.class.security.current_user_method)
        record = current_user.send(active_scaffold_config.config_list.save_to_user, active_scaffold_session_storage_key, controller_name)
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
        @last_modified = [@last_modified, config_list_record.updated_at].compact.maximum if config_list_record.respond_to? :updated_at
        objects = super
        if objects.is_a? Hash
          objects.merge(:etag => [objects[:etag], config_list_record])
        else
          [objects, config_list_record]
        end
      else
        super
      end
    end

    def config_list_record
      return @config_list_record if defined? @config_list_record
      @config_list_record = if active_scaffold_config.config_list.save_to_user
        current_user = send(active_scaffold_config.class.security.current_user_method)
        if current_user
          current_user.send(active_scaffold_config.config_list.save_to_user, active_scaffold_session_storage_key, controller_name)
        end
      end
    end

    def config_list_params
      @config_list_params = if config_list_record 
        params = config_list_record.config_list
        params.split(',').map(&:to_sym) if params
      else
        config_list_session_storage['config_list']
      end unless defined? @config_list_params
      @config_list_params || active_scaffold_config.config_list.default_columns
    end

    def config_list_sorting
      @config_list_sorting = if config_list_record 
        config_list_record.config_list_sorting if config_list_record.respond_to? :config_list_sorting
      else
        config_list_session_storage['config_list_sorting']
      end unless defined? @config_list_sorting
      @config_list_sorting
    end

    def list_columns
      @list_columns ||= begin
        columns = super
        if config_list_params.present?
          config_list = Hash[config_list_params.each_with_index.map{|c,i| [c,i]}]
          columns.select{|column| config_list.include? column.name}.sort{|x,y| config_list[x.name] <=> config_list[y.name]}
        else
          columns
        end
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def config_list_authorized?
      authorized_for?(:action => :read)
    end
  end
end
