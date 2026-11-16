# frozen_string_literal: true

require 'test_helper'
require 'action_view'
require 'active_record'
require 'active_scaffold/extensions/routing_mapper'

class PluginTest < Minitest::Test
  UI_ELEMENT_TAGS = {
    config_list_views: :div,
    config_list_view_selected: :div,
    config_list_views_list: :ul,
    config_list_view_item: :li,
    config_list_view_label: :label,
    config_list_sorting: :ol,
    config_list_sorting_item: :li,
    config_list_view_rename: :label,
    config_list_view_global: :label
  }.freeze

  def test_entry_point_registers_ui_elements_and_assets
    UI_ELEMENT_TAGS.each do |name, tag|
      assert_equal tag, ActiveScaffold.ui_elements.fetch(name).fetch(:tag)
    end
    assert_includes ActiveScaffold.stylesheets, 'active_scaffold_config_list'
    assert_includes ActiveScaffold.javascripts, 'active_scaffold_config_list'
  end

  def test_entry_point_makes_plugin_constants_available
    expected_sources = {
      ActiveScaffold::Actions::ConfigList.instance_method(:show_config_list) =>
        'lib/active_scaffold/actions/config_list.rb',
      ActiveScaffold::Config::ConfigList.instance_method(:add_view) =>
        'lib/active_scaffold/config/config_list.rb',
      ActiveScaffold::DataStructures::NamedView.instance_method(:initialize) =>
        'lib/active_scaffold/data_structures/named_view.rb',
      ActiveScaffold::Helpers::ConfigListHelpers.instance_method(:config_list_columns) =>
        'lib/active_scaffold/helpers/config_list_helpers.rb'
    }

    expected_sources.each do |method, relative_path|
      assert_equal File.expand_path("../#{relative_path}", __dir__), method.source_location.first
    end
  end

  def test_engine_defines_all_initializers
    assert_equal(
      %w[
        active_scaffold_config_list.routes
        active_scaffold_config_list.action_view
        active_scaffold_config_list.active_record
      ],
      ActiveScaffoldConfigList::Engine.initializers.map(&:name)
    )
  end

  def test_routes_initializer_registers_collection_routes
    run_initializer('active_scaffold_config_list.routes')

    routes = ActiveScaffold::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING.fetch(:collection)
    assert_equal :get, routes[:show_config_list]
    assert_equal :post, routes[:config_list]
  end

  def test_action_view_initializer_installs_helpers
    run_initializer('active_scaffold_config_list.action_view')

    assert_includes ActionView::Base.ancestors, ActiveScaffold::Helpers::ConfigListHelpers
  end

  def test_active_record_initializer_installs_config_listable
    run_initializer('active_scaffold_config_list.active_record')

    assert_includes ActiveRecord::Base.ancestors, ActiveScaffoldConfigList::ConfigListable
  end

  private

  def run_initializer(name)
    ActiveScaffoldConfigList::Engine.initializers.find { |initializer| initializer.name == name }.run
  end
end
