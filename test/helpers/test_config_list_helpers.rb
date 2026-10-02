# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/core_ext/string/output_safety'
require 'active_support/core_ext/erb/util'

module ActiveScaffold
  module Helpers
  end
end

require_relative '../../lib/active_scaffold/helpers/config_list_helpers'

class ConfigListHelpersTest < Minitest::Test
  class BaseHelper
    def ignore_param_for_nested?(key)
      key == :existing_nested_param
    end
  end

  class Helper < BaseHelper
    include ActiveScaffold::Helpers::ConfigListHelpers

    attr_accessor :selector
    attr_reader :element_calls, :link_calls, :radio_calls, :select_calls

    def initialize
      @element_calls = []
      @link_calls = []
      @radio_calls = []
      @select_calls = []
      @selector = :radio
    end

    def active_scaffold_config
      Struct.new(:config_list).new(Struct.new(:named_views_selector).new(selector))
    end

    def as_element(key, **options)
      @element_calls << [key, options]
      yield
    end

    def as_element_attributes(key, **options)
      @element_calls << [key, options]
      options
    end

    def radio_button_tag(name, value, selected, options)
      @radio_calls << [name, value, selected, options]
      '<input>'.dup
    end

    def link_to(label, url, options)
      @link_calls << [label, url, options]
      label
    end

    def select_tag(name, html, options)
      @select_calls << [name, html, options]
      html
    end

    def content_tag(_tag, content, **_options)
      content
    end

    def params_for(**_options)
      {}
    end

    def url_for(_options)
      '/items?config_list_view=--VIEW--'
    end

    def options_for_select(options, _selected)
      options.join
    end

    def user_named_views
      []
    end

    def named_views_from_config
      [['Compact', 'compact', 'Fewer columns']]
    end

    def params
      {}
    end

    def as_(key)
      key.to_s
    end

    def safe_join(values)
      values.join
    end
  end

  def test_config_list_view_is_not_copied_to_nested_links
    helper = Helper.new

    assert helper.ignore_param_for_nested?(:config_list_view)
    assert helper.ignore_param_for_nested?(:existing_nested_param)
    refute helper.ignore_param_for_nested?(:other_param)
  end

  def test_radio_view_uses_ui_elements_and_tooltip
    helper = Helper.new

    assert_equal '<input>Compact', helper.config_list_view_options([['Compact', 'compact', 'Fewer columns']], 'compact')
    assert_equal [
      [:config_list_view_radio, {id: nil}],
      [:config_list_view_label, {title: 'Fewer columns'}]
    ], helper.element_calls
    assert_equal [['config_list_view', 'compact', true, {id: nil}]], helper.radio_calls
  end

  def test_link_view_uses_ui_element_attributes_and_tooltip
    helper = Helper.new
    helper.selector = :links

    helper.config_list_view_options([['Compact', 'compact', 'Fewer columns']], 'compact')

    assert_equal [[:config_list_view_link, {remote: true, title: 'Fewer columns'}]], helper.element_calls
    assert_equal [['Compact', '/items?config_list_view=compact', {remote: true, title: 'Fewer columns'}]], helper.link_calls
  end

  def test_select_view_uses_ui_element_attributes
    helper = Helper.new
    helper.selector = :select

    helper.active_scaffold_named_view_selector

    assert_includes helper.element_calls, [:config_list_view_select, {id: nil}]
    assert_equal 'config_list_view', helper.select_calls.first.first
    assert_equal({id: nil}, helper.select_calls.first.last)
  end
end
