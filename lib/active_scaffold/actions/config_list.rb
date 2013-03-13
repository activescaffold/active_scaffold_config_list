module ActiveScaffold::Actions
  module ConfigList
    
    def self.included(base)
      base.before_filter :store_config_list_params, :only => [:index]
      base.helper_method :config_list_params
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

    def store_config_list_params
      if params[:config_list]
        config_list = params.delete :config_list
        case config_list
        when String
          delete_config_list_params
        when Array
          save_config_list_params(config_list)
        end
      end
    end

    def delete_config_list_params
      if active_scaffold_config.config_list.save_to_user && current_user = send(ActiveRecordPermissions.current_user_method)
        current_user.send(active_scaffold_config.config_list.save_to_user, active_scaffold_session_storage_key).destroy
      else
        active_scaffold_session_storage[:config_list] = nil
      end
      @config_list_params = nil
    end

    def save_config_list_params(config_list)
      if active_scaffold_config.config_list.save_to_user && current_user = send(ActiveRecordPermissions.current_user_method)
        current_user.send(active_scaffold_config.config_list.save_to_user, active_scaffold_session_storage_key).update_attribute :config_list, config_list.join(',')
      else
        active_scaffold_session_storage[:config_list] = config_list.map(&:to_sym)
      end
      @config_list_params = config_list.map(&:to_sym)
    end

    def config_list_params
      @config_list_params = if active_scaffold_config.config_list.save_to_user && current_user = send(ActiveRecordPermissions.current_user_method)
        params = current_user.send(active_scaffold_config.config_list.save_to_user, active_scaffold_session_storage_key).config_list
        params.split(',').map(&:to_sym) if params
      else
        active_scaffold_session_storage[:config_list]
      end unless defined? @config_list_params
      @config_list_params || active_scaffold_config.config_list.default_columns
    end

    def list_columns
      columns = super
      if !config_list_params.nil? && config_list_params.is_a?(Array)
        config_list = Hash[config_list_params.each_with_index.map]
        columns.select{|column| config_list.include? column.name}.sort{|x,y| config_list[x.name] <=> config_list[y.name]}
      else
        columns
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def config_list_authorized?
      authorized_for?(:action => :read)
    end
  end
end
