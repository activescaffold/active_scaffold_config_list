# frozen_string_literal: true

require 'minitest/autorun'

module ActiveScaffold
  module DataStructures
  end
end

require_relative '../../lib/active_scaffold/data_structures/named_view'

class NamedViewTest < Minitest::Test
  def test_custom_view
    named_view = ActiveScaffold::DataStructures::NamedView.allocate

    named_view.view = 'compact_list'

    assert_equal 'compact_list', named_view.view
  end
end
