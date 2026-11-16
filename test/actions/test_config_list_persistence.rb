# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/object/blank'

module ActiveScaffold
  module Actions
  end

  module Config
    class ConfigList
      unless respond_to?(:slug_builder)
        def self.slug_builder
          nil
        end
      end
    end
  end
end

require_relative '../../lib/active_scaffold/actions/config_list'

class ConfigListPersistenceTest < Minitest::Test
  ConfigListConfig = Struct.new(:save_to_user, :global_views, :named_views_method, :default_columns)
  ListConfig = Struct.new(:user)
  Config = Struct.new(:config_list, :list)

  class Record
    attr_accessor :config_list, :config_list_sorting
    attr_reader :destroyed, :saved

    def destroy
      @destroyed = true
    end

    def save
      @saved = true
    end
  end

  class User
    attr_reader :calls
    attr_accessor :record, :views

    def initialize
      @calls = []
      @record = Record.new
      @views = []
    end

    def config_for(*args, **options)
      calls << [:config_for, args, options]
      record
    end

    def config_views(*args)
      calls << [:config_views, args]
      views
    end
  end

  class Controller
    def self.before_action(*); end

    def self.helper_method(*); end

    include ActiveScaffold::Actions::ConfigList

    attr_reader :active_scaffold_config, :params, :storage
    attr_accessor :current_user

    def initialize
      @params = {}
      @storage = {}
      config_list = ConfigListConfig.new(nil, false, nil, [:fallback])
      @active_scaffold_config = Config.new(config_list, ListConfig.new({}))
    end

    def active_scaffold_session_storage
      @storage
    end

    def active_scaffold_session_storage_key
      'session-key'
    end

    def controller_name
      'tasks'
    end

    def active_scaffold_current_user
      current_user
    end

    public :config_list_named_views, :config_list_params, :config_list_record_assignment,
           :config_list_slug, :config_list_sorting, :config_list_sorting_params,
           :delete_config_list_params, :save_config_list_params
  end

  def test_saves_columns_and_sorting_in_session
    controller = Controller.new

    controller.save_config_list_params(%w[name status], [%i[name asc]], nil, nil)

    assert_equal %i[name status], controller.storage['config_list']
    assert_equal [%i[name asc]], controller.storage['config_list_sorting']
  end

  def test_deleting_session_configuration_clears_columns_sorting_and_active_sort
    controller = Controller.new
    controller.save_config_list_params(['name'], [%i[name asc]], nil, nil)
    controller.active_scaffold_config.list.user['sort'] = [:name]

    controller.delete_config_list_params(nil)

    assert_nil controller.storage['config_list']
    assert_nil controller.storage['config_list_sorting']
    assert_nil controller.active_scaffold_config.list.user['sort']
  end

  def test_sorting_params_discards_incomplete_rows
    controller = Controller.new
    controller.params[:config_list_sorting] = {
      '0' => %w[name asc],
      '1' => ['', 'desc'],
      '2' => ['status', '']
    }

    assert_equal [%w[name asc]], controller.config_list_sorting_params
    refute_includes controller.params, :config_list_sorting
  end

  def test_sorting_params_returns_nil_when_no_complete_rows_remain
    controller = Controller.new
    controller.params[:config_list_sorting] = {'0' => ['', '']}

    assert_nil controller.config_list_sorting_params
  end

  def test_slug_prefixes_distinguish_user_and_global_views
    controller = Controller.new
    controller.active_scaffold_config.config_list.global_views = true

    assert_equal 'user-Daily', controller.config_list_slug('Daily', false)
    assert_equal 'global-Daily', controller.config_list_slug('Daily', true)
  end

  def test_slug_is_plain_view_name_when_global_views_are_disabled
    controller = Controller.new

    assert_equal 'Daily', controller.config_list_slug('Daily', true)
  end

  def test_saves_global_named_view_to_current_user
    controller = Controller.new
    controller.current_user = User.new
    controller.active_scaffold_config.config_list.save_to_user = :config_for
    controller.active_scaffold_config.config_list.global_views = true
    controller.params[:global_view] = '1'

    controller.save_config_list_params(%w[name status], [%i[name asc]], 'Daily', nil)

    record = controller.current_user.record
    assert_equal 'name,status', record.config_list
    assert_equal [%i[name asc]], record.config_list_sorting
    assert record.saved
    assert_equal 'global-Daily', controller.params[:config_list_view]
    assert_equal [
      :config_for,
      %w[session-key tasks],
      {attributes: {view_name: 'Daily', slug: 'global-Daily'}, slug: 'global-Daily'}
    ], controller.current_user.calls.first
    refute_includes controller.params, :global_view
  end

  def test_deletes_persisted_named_view_and_reloads_record
    controller = Controller.new
    controller.current_user = User.new
    controller.active_scaffold_config.config_list.save_to_user = :config_for

    controller.delete_config_list_params('Daily')

    assert controller.current_user.record.destroyed
    assert_equal 2, controller.current_user.calls.size
  end

  def test_loads_columns_and_sorting_from_persisted_record
    controller = Controller.new
    controller.current_user = User.new
    controller.active_scaffold_config.config_list.save_to_user = :config_for
    controller.current_user.record.config_list = 'name,status'
    controller.current_user.record.config_list_sorting = [%i[status desc]]

    assert_equal %i[name status], controller.config_list_params
    assert_equal [%i[status desc]], controller.config_list_sorting
  end

  def test_named_view_sorting_takes_precedence
    controller = Controller.new
    named_view = Struct.new(:sorting).new([%i[created_at desc]])
    controller.define_singleton_method(:named_view) { named_view }

    assert_equal [%i[created_at desc]], controller.config_list_sorting
  end

  def test_uses_default_columns_when_no_configuration_is_saved
    controller = Controller.new

    assert_equal [:fallback], controller.config_list_params
    assert_nil controller.config_list_sorting
  end

  def test_loads_named_views_from_current_user_and_removes_nil_entries
    controller = Controller.new
    controller.current_user = User.new
    controller.current_user.views = [%w[Daily daily], nil]
    controller.active_scaffold_config.config_list.named_views_method = :config_views

    assert_equal [%w[Daily daily]], controller.config_list_named_views
    assert_equal [:config_views, %w[session-key tasks]], controller.current_user.calls.first
  end

  def test_record_assignment_uses_plain_name_without_global_views
    controller = Controller.new

    assert_equal({view_name: 'Daily'}, controller.config_list_record_assignment('Daily'))
    assert_nil controller.config_list_record_assignment(nil)
  end
end
