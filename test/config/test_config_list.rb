# frozen_string_literal: true

require 'test_helper'

class ConfigListConfigTest < Minitest::Test
  Association = Struct.new(:polymorphic?)
  Column = Struct.new(:name, :association)

  class Columns < Array
    def _inheritable
      map(&:name)
    end
  end

  class Core
    attr_reader :columns

    def initialize
      @columns = Columns.new([
                               Column.new(:name),
                               Column.new(:created_at),
                               Column.new(:updated_at),
                               Column.new(:attachable, Association.new(true)),
                               Column.new(:account, Association.new(false))
                             ])
    end

    def build_action_columns(action, values)
      ActiveScaffold::DataStructures::ActionColumns.new(values).tap do |columns|
        columns.action = action
      end
    end

    def label(count:)
      count == 1 ? 'Task' : 'Tasks'
    end

    def model_id
      :task
    end

    def user
      self
    end
  end

  def setup
    @config = ActiveScaffold::Config::ConfigList.new(Core.new)
  end

  def test_class_and_instance_defaults
    assert_equal :read, ActiveScaffold::Config::ConfigList.crud_type
    assert_equal File.expand_path('../..', __dir__), ActiveScaffold::Config::ConfigList.plugin_directory
    assert_equal :center, @config.named_views_position
    assert_equal :links, @config.named_views_selector
    assert @config.draggable
    assert_nil @config.save_to_user
    assert_nil @config.named_views_method
    assert_nil @config.default_view
    assert_nil @config.unnamed_view_security_method
    assert_nil @config.global_views
    assert_empty @config.named_views

    assert_equal 'show_config_list', @config.link.action
    assert_equal :collection, @config.link.type
    assert_equal :config_list_authorized?, @config.link.security_method
    refute_same ActiveScaffold::Config::ConfigList.link, @config.link
  end

  def test_label_uses_the_singular_model_label
    @config.define_singleton_method(:as_) { |key, options| [key, options] }

    assert_equal [:config_list_model, {model: 'Task'}], @config.label
  end

  def test_columns_exclude_timestamps_marked_and_polymorphic_columns
    assert_equal %i[name account], @config.columns.to_a
    assert_same @config, @config.columns.action
  end

  def test_adds_named_view_with_columns_and_configuration
    view = @config.add_view(:compact, %i[name account]) do |named_view|
      named_view.tooltip = 'Compact view'
      named_view.sorting = [%i[name asc]]
    end

    assert_equal 'compact', view.name
    assert_equal %i[name account], view.columns.to_a
    assert_equal 'Compact view', view.tooltip
    assert_equal [%i[name asc]], view.sorting
    assert_same view, @config.named_views.first
  end

  def test_custom_view_does_not_require_columns
    view = @config.add_view(:cards) { |named_view| named_view.view = 'cards' }

    assert_equal 'cards', view.view
    assert_empty view.columns
  end

  def test_rejects_duplicate_and_empty_named_views
    @config.add_view(:compact, [:name])

    error = assert_raises(ArgumentError) { @config.add_view(:compact, [:account]) }
    assert_equal "view 'compact' already exists", error.message

    error = assert_raises(ArgumentError) { @config.add_view(:empty) }
    assert_equal "no columns defined for view 'empty'", error.message
  end

  def test_user_settings_delegate_to_configuration
    @config.default_columns = [:name]
    @config.save_to_user = :config_for
    @config.named_views_method = :config_views
    @config.named_views_position = :left
    @config.named_views_selector = :select
    @config.default_view = 'compact'
    @config.unnamed_view_security_method = :show_default_view?
    @config.global_views = true
    @config.draggable = false
    @config.define_singleton_method(:as_) { |key, options| [key, options] }

    settings = ActiveScaffold::Config::ConfigList::UserSettings.new(@config, {}, {})

    assert_equal [:name], settings.default_columns
    assert_equal :config_for, settings.save_to_user
    assert_equal :config_views, settings.named_views_method
    assert_equal :left, settings.named_views_position
    assert_equal :select, settings.named_views_selector
    assert_equal 'compact', settings.default_view
    assert_equal :show_default_view?, settings.unnamed_view_security_method
    assert settings.global_views
    refute settings.draggable
    assert_equal [:config_list_model, {model: 'Task'}], settings.label
  end
end
