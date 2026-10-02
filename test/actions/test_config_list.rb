# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/core_ext/object/blank'

module ActiveScaffold
  module Actions
  end
end

require_relative '../../lib/active_scaffold/actions/config_list'

class ConfigListTest < Minitest::Test
  NamedView = Struct.new(:name)
  ConfigList = Struct.new(:named_views, :default_view)
  Config = Struct.new(:config_list)

  class Controller
    def self.before_action(*)
    end

    def self.helper_method(*)
    end

    include ActiveScaffold::Actions::ConfigList

    attr_reader :params

    def initialize(view, selected: view.name, default_view: nil)
      @params = {config_list_view: selected}
      @active_scaffold_config = Config.new(ConfigList.new([view], default_view))
    end

    def active_scaffold_config
      @active_scaffold_config
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
end
