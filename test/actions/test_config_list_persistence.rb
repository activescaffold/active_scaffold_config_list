# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/core_ext/object/blank'

module ActiveScaffold
  module Actions
  end

  module Config
    class ConfigList
      def self.slug_builder
        nil
      end
    end
  end
end

require_relative '../../lib/active_scaffold/actions/config_list'

class ConfigListPersistenceTest < Minitest::Test
  ConfigListConfig = Struct.new(:save_to_user, :global_views)
  ListConfig = Struct.new(:user)
  Config = Struct.new(:config_list, :list)

  class Controller
    def self.before_action(*); end

    def self.helper_method(*); end

    include ActiveScaffold::Actions::ConfigList

    attr_reader :active_scaffold_config, :params, :storage

    def initialize
      @params = {}
      @storage = {}
      @active_scaffold_config = Config.new(ConfigListConfig.new(nil, false), ListConfig.new({}))
    end

    def active_scaffold_session_storage
      @storage
    end

    public :config_list_slug, :config_list_sorting_params, :delete_config_list_params, :save_config_list_params
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
end
