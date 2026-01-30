# frozen_string_literal: true

module ActiveScaffold::DataStructures
  class NamedView
    # the internal name of the view
    attr_reader :name

    # the label displayed to the user, if it's a symbol will be translated with as_
    attr_writer :label

    # the method used to check permissions, if returns true, the list view is allowed
    attr_accessor :security_method

    # the columns in the named view
    attr_reader :columns

    # default sorting used with this view instead of default
    attr_accessor :sorting

    def initialize(name, action)
      @name = name.to_s
      @action = action
      @label = name
    end

    # the label displayed to the user
    def label
      case @label
      when Symbol
        ActiveScaffold::Registry.cache(:translations, @label) { as_(@label) }
      else
        @label
      end
    end

    def columns=(columns)
      @columns = ActionColumns.new(columns).tap { |cols| cols.action = @action }
    end
  end
end
