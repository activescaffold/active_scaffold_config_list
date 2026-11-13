# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support/concern'
require 'active_support/core_ext/hash/keys'

require_relative '../../lib/active_scaffold_config_list/config_listable'

class ConfigListableTest < Minitest::Test
  class Record
    attr_accessor :attributes
  end

  class Query
    attr_reader :calls
    attr_accessor :pluck_result, :record

    def initialize
      @calls = []
      @record = Record.new
      @pluck_result = []
    end

    def where(criteria = :chain)
      if criteria == :chain
        WhereChain.new(self)
      else
        calls << [:where, criteria]
        self
      end
    end

    def or(other)
      calls << [:or, other]
      self
    end

    def first_or_initialize
      calls << [:first_or_initialize]
      record
    end

    def pluck(columns)
      calls << [:pluck, columns]
      pluck_result
    end

    class WhereChain
      def initialize(query)
        @query = query
      end

      def not(criteria)
        @query.calls << [:where_not, criteria]
        @query
      end
    end
  end

  class GlobalModel
    class << self
      attr_accessor :query

      def where(criteria)
        query.calls << [:where, criteria]
        query
      end
    end
  end

  class User
    include ActiveScaffoldConfigList::ConfigListable::InstanceMethods

    class << self
      attr_accessor :config_list_settings
    end

    attr_reader :association

    def initialize(association)
      @association = association
    end

    def configurations
      association
    end
  end

  def setup
    @association = Query.new
    @global_query = Query.new
    GlobalModel.query = @global_query
    User.config_list_settings = {
      association_name: :configurations,
      model_class: GlobalModel,
      foreign_key: :user_id,
      controller_column: :controller_key,
      controller_matcher: :controller_name,
      view_name_column: :name,
      slug_column: :slug
    }
    @user = User.new(@association)
  end

  def test_finds_private_view_only_through_user_association
    record = @user.config_list_for('session-key', 'tasks', slug: 'user-daily')

    assert_same @association.record, record
    assert_includes @association.calls, [:where, {controller_key: 'tasks'}]
    assert_includes @association.calls, [:where, {slug: 'user-daily'}]
    assert_empty @global_query.calls
  end

  def test_global_view_combines_global_and_user_records
    record = @user.config_list_for('session-key', 'tasks', slug: 'global-daily')

    assert_same @global_query.record, record
    assert_includes @global_query.calls, [:where, {user_id: nil}]
    assert_includes @global_query.calls, [:or, @association]
    assert_includes @global_query.calls, [:where, {controller_key: 'tasks'}]
    assert_includes @global_query.calls, [:where, {slug: 'global-daily'}]
  end

  def test_controller_id_matcher_uses_session_storage_key
    User.config_list_settings = User.config_list_settings.merge(controller_matcher: :controller_id)

    @user.config_list_for('session-key', 'tasks')

    assert_includes @association.calls, [:where, {controller_key: 'session-key'}]
  end

  def test_callable_controller_matcher_builds_custom_condition
    matcher = ->(id, name) { {controller_key: "#{name}:#{id}"} }
    User.config_list_settings = User.config_list_settings.merge(controller_matcher: matcher)

    @user.config_list_for('session-key', 'tasks')

    assert_includes @association.calls, [:where, {controller_key: 'tasks:session-key'}]
  end

  def test_maps_public_attribute_names_to_custom_columns
    record = @user.config_list_for(
      'session-key',
      'tasks',
      attributes: {'view_name' => 'Daily', 'slug' => 'user-daily', 'config_list' => 'name,status'}
    )

    assert_equal(
      {name: 'Daily', slug: 'user-daily', config_list: 'name,status'},
      record.attributes
    )
  end

  def test_named_views_include_global_records_and_pluck_names_and_slugs
    @global_query.pluck_result = [%w[Daily global-daily]]

    assert_equal [%w[Daily global-daily]], @user.config_list_views('session-key', 'tasks')
    assert_includes @global_query.calls, [:where_not, {name: nil}]
    assert_includes @global_query.calls, [:pluck, %i[name slug]]
  end
end
