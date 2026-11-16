# frozen_string_literal: true

require 'test_helper'
require 'active_support/core_ext/object/blank'

module ActiveScaffold
  unless const_defined?(:ActionNotAllowed)
    class ActionNotAllowed < StandardError; end
  end

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

class ConfigListTest < Minitest::Test
  NamedView = Struct.new(:name)
  ConfigList = Struct.new(:named_views, :default_view)
  Config = Struct.new(:config_list)
  Column = Struct.new(:name)

  class Sorting
    attr_reader :values

    def set(*values)
      @values = values
    end
  end

  class UserSettings < Hash
    attr_reader :sorting

    def initialize
      super
      @sorting = Sorting.new
    end
  end

  class ViewColumns
    def initialize(columns)
      @columns = columns
    end

    def visible_columns(flatten:)
      raise 'flatten is required' unless flatten

      @columns
    end
  end

  BehaviorNamedView = Struct.new(:name, :columns, :security_method, :sorting)
  BehaviorConfigList = Struct.new(:named_views, :global_views, :default_columns)
  BehaviorList = Struct.new(:refresh_with_header, :user)
  BehaviorConfig = Struct.new(:config_list, :list)

  class BaseController
    attr_accessor :base_columns, :base_objects
    attr_reader :refresh_calls

    def list_columns
      base_columns
    end

    def objects_for_etag
      base_objects
    end

    def do_refresh_list
      @refresh_calls = (refresh_calls || 0) + 1
    end
  end

  class BehaviorController < BaseController
    def self.before_action(*); end

    def self.helper_method(*); end

    include ActiveScaffold::Actions::ConfigList

    attr_reader :params, :active_scaffold_config, :persistence_call, :response_call
    attr_accessor :record, :named_views, :saved_sorting, :authorized

    def initialize
      super
      @params = {}
      @named_views = []
      @authorized = true
      config_list = BehaviorConfigList.new([], false, [:fallback])
      @active_scaffold_config = BehaviorConfig.new(config_list, BehaviorList.new(false, UserSettings.new))
    end

    def config_list_record(*)
      record
    end

    def config_list_named_views
      named_views
    end

    def config_list_sorting
      saved_sorting
    end

    def delete_config_list_params(view_name)
      @persistence_call = [:delete, view_name]
    end

    def save_config_list_params(*arguments)
      @persistence_call = [:save, arguments]
    end

    def respond_to_action(action, formats)
      @response_call = [:respond_to_action, action, formats]
    end

    def render(**options)
      @response_call = [:render, options]
    end

    def redirect_to(**options)
      @response_call = [:redirect_to, options]
    end

    def params_for(**options)
      options
    end

    def url_for(options)
      "/#{options[:action]}?config_list_view=#{options[:config_list_view]}"
    end

    def authorized_for?(action:)
      action == :read && authorized
    end

    def allowed_named_view?
      authorized
    end

    public :change_view, :config_list_authorized?, :config_list_authorized_filter,
           :config_list_formats, :config_list_respond_to_html, :config_list_respond_to_js,
           :find_view_name, :list_columns, :named_view_columns, :objects_for_etag,
           :set_default_sorting, :show_config_list_respond_to_html,
           :show_config_list_respond_to_js
  end

  class Controller
    def self.before_action(*); end

    def self.helper_method(*); end

    include ActiveScaffold::Actions::ConfigList

    attr_reader :params, :active_scaffold_config

    def initialize(view, selected: view.name, default_view: nil)
      @params = {config_list_view: selected}
      @active_scaffold_config = Config.new(ConfigList.new([view], default_view))
    end

    public :named_view, :set_default_view
  end

  def test_named_view_remains_available_after_parameter_is_removed
    view = NamedView.new('compact')
    controller = Controller.new(view)

    assert_same view, controller.named_view

    controller.params.delete(:config_list_view)

    assert_same view, controller.named_view
  end

  def test_default_view_is_selected_when_parameter_is_nil
    view = NamedView.new('Calendar')
    controller = Controller.new(view, selected: nil, default_view: 'Calendar')

    controller.set_default_view

    assert_equal 'Calendar', controller.params[:config_list_view]
  end

  def test_explicit_empty_view_does_not_select_the_default
    view = NamedView.new('Calendar')
    controller = Controller.new(view, selected: '', default_view: 'Calendar')

    controller.set_default_view

    assert_equal '', controller.params[:config_list_view]
  end

  def test_show_config_list_resolves_global_view_and_responds_to_supported_formats
    controller = BehaviorController.new
    controller.record = Object.new
    controller.named_views = [%w[Daily global-Daily]]
    controller.active_scaffold_config.config_list.global_views = true
    controller.params[:config_list_view] = 'global-Daily'

    controller.show_config_list

    assert_equal [:respond_to_action, :show_config_list, %i[html js]], controller.response_call
    assert_equal 'Daily', controller.instance_variable_get(:@config_list_view_name)
    assert controller.instance_variable_get(:@global_view)
  end

  def test_response_helpers_render_and_redirect_with_expected_options
    controller = BehaviorController.new

    controller.show_config_list_respond_to_html
    assert_equal [:render, {action: 'show_config_list_form', layout: true}], controller.response_call

    controller.show_config_list_respond_to_js
    assert_equal [:render, {partial: 'show_config_list_form', layout: false}], controller.response_call

    controller.params[:config_list_view_name] = 'Daily'
    controller.config_list_respond_to_html
    assert_equal(
      [:redirect_to, {action: :index, config_list_view: 'Daily'}],
      controller.response_call
    )
  end

  def test_config_list_dispatches_delete_request
    controller = BehaviorController.new
    controller.params[:config_list] = 'delete'
    controller.params[:config_list_view] = 'Daily'

    controller.config_list

    assert_equal [:delete, 'Daily'], controller.persistence_call
    assert_equal [:respond_to_action, :config_list, %i[html js]], controller.response_call
    refute_includes controller.params, :config_list
    refute_includes controller.params, :config_list_view
  end

  def test_config_list_dispatches_save_request
    controller = BehaviorController.new
    controller.params[:config_list] = %w[name status]
    controller.params[:config_list_sorting] = {'0' => %w[status desc]}
    controller.params[:config_list_view_name] = 'Daily'
    controller.params[:config_list_old_view_name] = 'Old Daily'

    controller.config_list

    assert_equal(
      [:save, [%w[name status], [%w[status desc]], 'Daily', 'Old Daily']],
      controller.persistence_call
    )
  end

  def test_js_response_refreshes_list_and_updates_history_url
    controller = BehaviorController.new
    controller.params[:config_list_view] = 'Daily'

    controller.config_list_respond_to_js

    assert_equal 1, controller.refresh_calls
    assert controller.active_scaffold_config.list.refresh_with_header
    assert_equal(
      [
        :render,
        {
          partial: 'refresh_list',
          locals: {history_url: '/index?config_list_view=Daily'},
          formats: [:js]
        }
      ],
      controller.response_call
    )
  end

  def test_default_sorting_is_applied_when_request_and_user_sorting_are_blank
    controller = BehaviorController.new
    controller.saved_sorting = %i[name desc]

    controller.set_default_sorting

    assert_equal %i[name desc], controller.active_scaffold_config.list.user.sorting.values
  end

  def test_list_columns_follow_saved_selection_order
    controller = BehaviorController.new
    controller.base_columns = [Column.new(:name), Column.new(:status), Column.new(:created_at)]
    controller.define_singleton_method(:config_list_params) { %i[status name] }

    assert_equal %i[status name], controller.list_columns.map(&:name)
  end

  def test_named_view_columns_check_security_method
    controller = BehaviorController.new
    columns = [Column.new(:name)]
    view = BehaviorNamedView.new('private', ViewColumns.new(columns), :allowed_named_view?, nil)
    controller.active_scaffold_config.config_list.named_views = [view]
    controller.params[:config_list_view] = 'private'

    assert_equal columns, controller.named_view_columns

    controller.authorized = false
    assert_raises(ActiveScaffold::ActionNotAllowed) { controller.named_view_columns }
  end

  def test_authorization_requires_unnamed_view_and_read_access
    controller = BehaviorController.new

    assert controller.config_list_authorized?
    controller.authorized = false
    refute controller.config_list_authorized?
    assert_raises(ActiveScaffold::ActionNotAllowed) { controller.config_list_authorized_filter }
  end

  def test_objects_for_etag_include_saved_configuration
    controller = BehaviorController.new
    controller.base_columns = [Column.new(:name)]
    controller.define_singleton_method(:config_list_params) { nil }
    controller.list_columns
    controller.record = Struct.new(:updated_at).new(Time.utc(2026, 1, 2))
    controller.base_objects = {etag: [:base]}

    objects = controller.objects_for_etag

    assert_equal [[:base], controller.record], objects[:etag]
    assert_equal controller.record.updated_at, controller.instance_variable_get(:@last_modified)
  end

  def test_objects_for_etag_append_record_to_non_hash_values
    controller = BehaviorController.new
    controller.base_columns = [Column.new(:name)]
    controller.define_singleton_method(:config_list_params) { nil }
    controller.list_columns
    controller.record = Object.new
    controller.base_objects = [:base]

    assert_equal [[:base], controller.record], controller.objects_for_etag
  end

  def test_objects_for_etag_uses_base_objects_before_list_columns_are_loaded
    controller = BehaviorController.new
    controller.base_objects = [:base]

    assert_equal [:base], controller.objects_for_etag
  end

  def test_view_changes_request_header_refresh
    controller = BehaviorController.new
    controller.params[:config_list_view] = 'Daily'

    controller.change_view

    assert controller.active_scaffold_config.list.refresh_with_header
    assert_equal %i[html js], controller.config_list_formats
  end
end
