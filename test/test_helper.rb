# frozen_string_literal: true

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start
end
require 'minitest/autorun'
require 'rails'
require 'active_scaffold'
require 'active_scaffold_config_list'
