# frozen_string_literal: true

require 'test_helper'

require_relative '../../lib/active_scaffold/data_structures/named_view'

class NamedViewTest < Minitest::Test
  Action = Struct.new(:name)

  def test_initializes_name_label_and_columns
    action = Action.new(:config_list)
    named_view = ActiveScaffold::DataStructures::NamedView.new('compact', action)

    named_view.columns = %i[name status]

    assert_equal 'compact', named_view.name
    assert_equal 'compact', named_view.label
    assert_equal %i[name status], named_view.columns.to_a
    assert_same action, named_view.columns.action
  end

  def test_custom_view
    named_view = ActiveScaffold::DataStructures::NamedView.allocate

    named_view.view = 'compact_list'
    named_view.tooltip = 'Shows fewer columns'

    assert_equal 'compact_list', named_view.view
    assert_equal 'Shows fewer columns', named_view.tooltip
  end

  def test_symbol_label_is_translated
    named_view = ActiveScaffold::DataStructures::NamedView.new('compact', Action.new(:config_list))
    named_view.label = :config_list_compact_test_label
    named_view.define_singleton_method(:as_) { |key| "translated #{key}" }

    assert_equal 'translated config_list_compact_test_label', named_view.label
  end
end
