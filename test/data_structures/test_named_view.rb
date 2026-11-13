# frozen_string_literal: true

require 'minitest/autorun'

module ActiveScaffold
  module DataStructures
    class ActionColumns
      attr_accessor :action

      def initialize(columns)
        @columns = columns
      end

      def to_a
        @columns
      end
    end
  end
end

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
end
