# frozen_string_literal: true

require 'minitest/autorun'

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
  end

  def test_config_list_view_is_not_copied_to_nested_links
    helper = Helper.new

    assert helper.ignore_param_for_nested?(:config_list_view)
    assert helper.ignore_param_for_nested?(:existing_nested_param)
    refute helper.ignore_param_for_nested?(:other_param)
  end
end
