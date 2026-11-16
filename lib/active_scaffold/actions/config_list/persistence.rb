# frozen_string_literal: true

module ActiveScaffold::Actions::ConfigListPersistence
  protected

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
    assign = config_list_record_assignment(view_name)
    selected_view = assign&.dig(:slug) || view_name
    record = config_list_record(old_view_name || selected_view, assign: assign)

    if record
      save_config_list_record(record, config_list, config_list_sorting, selected_view)
    else
      save_config_list_session(config_list, config_list_sorting)
    end
    @config_list_params = config_list.map(&:to_sym)
    @config_list_sorting = config_list_sorting
  end

  def config_list_record_assignment(view_name)
    return if view_name.blank?

    assign = {view_name: view_name}
    if active_scaffold_config.config_list.global_views
      assign[:slug] = config_list_slug(view_name, params.delete(:global_view).present?)
    end
    assign
  end

  def save_config_list_record(record, config_list, config_list_sorting, selected_view)
    record.config_list = config_list.compact_blank.join(',')
    record.config_list_sorting = config_list_sorting if record.respond_to? :config_list_sorting
    params[:config_list_view] = selected_view if record.save
  end

  def save_config_list_session(config_list, config_list_sorting)
    config_list_session_storage['config_list'] = config_list.map(&:to_sym)
    config_list_session_storage['config_list_sorting'] = config_list_sorting
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
          params&.split(',')&.map(&:to_sym)
        else
          config_list_session_storage['config_list']
        end
    end
    @config_list_params || config_list_default_columns
  end

  def config_list_sorting
    unless defined? @config_list_sorting
      @config_list_sorting =
        if named_view
          named_view.sorting
        elsif config_list_record
          config_list_record.config_list_sorting if config_list_record.respond_to? :config_list_sorting
        else
          config_list_session_storage['config_list_sorting']
        end
    end
    @config_list_sorting
  end
end
