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
  class Attributes < Hash
    def extractable_options?
      false
    end
  end

  class BaseHelper
    def ignore_param_for_nested?(key)
      key == :existing_nested_param
    end
  end

  class Helper < BaseHelper
    include ActiveScaffold::Helpers::ConfigListHelpers

    attr_accessor :default_view_authorized, :default_view_security_method, :selector
    attr_reader :element_calls, :link_calls, :radio_calls, :select_calls

    def initialize
      @element_calls = []
      @link_calls = []
      @radio_calls = []
      @select_calls = []
      @default_view_authorized = true
      @selector = :radio
    end

    def active_scaffold_config
      config_list = Struct.new(:named_views_selector, :default_view_security_method)
      Struct.new(:config_list).new(config_list.new(selector, default_view_security_method))
    end

    def as_element(key, content = nil, **options)
      @element_calls << [key, options]
      block_given? ? yield : content
    end

    def as_element_attributes(key, **options)
      @element_calls << [key, options]
      Attributes.new.merge(options)
    end

    def radio_button_tag(name, value, *args)
      options = args.last.instance_of?(Hash) ? args.pop : {}
      selected = args.first || false
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

    def controller
      self
    end

    def default_view_authorized?
      default_view_authorized
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

    assert_equal [
      [:config_list_view_link, {remote: true, title: 'Fewer columns'}],
      [:config_list_view_item, {class: 'selected'}],
      [:config_list_view_selected, {class: 'selected-view'}],
      [:config_list_views_list, {class: 'views'}]
    ], helper.element_calls
    assert_equal [['Compact', '/items?config_list_view=compact', {remote: true, title: 'Fewer columns'}]], helper.link_calls
  end

  def test_select_view_uses_ui_element_attributes
    helper = Helper.new
    helper.selector = :select

    helper.active_scaffold_named_view_selector

    assert_includes helper.element_calls, [:config_list_view_option, {title: 'Fewer columns'}]
    assert_includes helper.element_calls, [:config_list_view_select, {id: nil}]
    assert_equal 'config_list_view', helper.select_calls.first.first
    assert_equal({id: nil}, helper.select_calls.first.last)
  end

  def test_default_view_can_be_hidden_with_security_method
    helper = Helper.new
    helper.default_view_security_method = :default_view_authorized?
    helper.default_view_authorized = false

    helper.active_scaffold_named_view_selector

    assert_equal ['compact'], helper.radio_calls.map { |call| call[1] }
  end
end
