# frozen_string_literal: true

module ActiveScaffold::Config
  class ConfigList < Base
    self.crud_type = :read
    def initialize(*args)
      super
      @link = self.class.link.clone unless self.class.link.nil?
      @save_to_user = self.class.save_to_user
      @named_views_method = self.class.named_views_method
      @draggable = self.class.draggable
      @named_views_position = self.class.named_views_position
      @named_views_selector = self.class.named_views_selector
      @default_view = self.class.default_view
      @unnamed_view_security_method = self.class.unnamed_view_security_method
      @global_views = self.class.global_views
      @named_views = []
    end

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_accessor :link,
                   instance_accessor: false,
                   default: ActiveScaffold::DataStructures::ActionLink.new(
                     'show_config_list',
                     label: :config_list,
                     type: :collection,
                     security_method: :config_list_authorized?
                   )

    # configures where the plugin itself is located. there is no instance version of this.
    cattr_accessor :plugin_directory,
                   instance_accessor: false,
                   default: File.expand_path(__FILE__).match(%r{(^.*)/lib/active_scaffold/config/config_list.rb})[1]

    # configures the method in user model to save list configuration for every controller
    cattr_accessor :save_to_user, instance_accessor: false, default: nil

    # configures the method in user model to return the named views saved for the user,
    # setting it enables saving the views, but requires to set a method in save_to_user
    cattr_accessor :named_views_method, instance_accessor: false, default: nil

    # the position to place the named views selector, :left (next to the title),
    # :right or :center (default, before the actions and filters)
    cattr_accessor :named_views_position, instance_accessor: false, default: :center

    # the type of selector for named views, :links, :select or :radio
    cattr_accessor :named_views_selector, instance_accessor: false, default: :links

    # named view selected when config_list_view is not present in the request
    cattr_accessor :default_view, instance_accessor: false, default: nil

    # method used to check whether the unnamed, configurable list view is available
    cattr_accessor :unnamed_view_security_method, instance_accessor: false, default: nil

    # if saving global views is allowed, or named views are always saved for the current user only
    cattr_accessor :global_views, instance_accessor: false, default: nil

    # Configures the method to convert a view name to slug, used only when global views are enabled
    # Slugs are needed when global views are enabled, to ensure the name in the params is unique
    # although a user view has the same name as a global view
    # By default is generated with the prefixes global- and user-, but a different method can be setup here
    # so it can be defined in ApplicationController
    cattr_accessor :slug_builder, instance_accessor: false, default: nil

    # enable draggable lists to select displayed columns (enabled by default)
    cattr_accessor :draggable, instance_accessor: false, default: true

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label(core: @core)
      @label ? as_(@label) : as_(:config_list_model, model: core.label(count: 1))
    end

    # if you do not want to show all columns as a default you may define some
    # e.g. conf.config_list.default_columns = [:name, founded_on]
    attr_accessor :default_columns

    # configures the method in user model to save list configuration for every controller
    attr_accessor :save_to_user

    # configures the method in user model to return the named views saved for the user,
    # setting it enables saving the views, but requires to set a method in save_to_user
    attr_accessor :named_views_method

    # the position to place the named views selector, :left (next to the title),
    # :right or :center (default, before the actions and filters)
    attr_accessor :named_views_position

    # the type of selector for named views, :links, :select or :radio
    attr_accessor :named_views_selector

    # named view selected when config_list_view is not present in the request
    attr_accessor :default_view

    # method used to check whether the unnamed, configurable list view is available
    attr_accessor :unnamed_view_security_method

    # if saving global views is allowed, or named views are always saved for the current user only
    attr_accessor :global_views

    # generic named views
    attr_reader :named_views

    # enable draggable lists to select displayed columns
    attr_accessor :draggable

    # provides access to the list of columns specifically meant for the config_list to use
    columns_accessor :columns do
      columns.exclude :created_on, :created_at, :updated_on, :updated_at, :as_marked
      columns.exclude(*@core.columns.select { |c| c.association.try(:polymorphic?) }.map(&:name))
    end

    # the ActionLink for this action
    attr_accessor :link

    def add_view(name, columns = nil, &)
      validate_new_view_name!(name)

      view = ::ActiveScaffold::DataStructures::NamedView.new(name, self)
      view.columns = columns if columns
      yield view if block_given?
      normalize_view_columns(view)
      validate_view_columns!(view)

      @named_views << view
      view
    end

    private

    def validate_new_view_name!(name)
      raise ArgumentError, "view '#{name}' already exists" if @named_views.any? { |view| view.name == name }
    end

    def normalize_view_columns(view)
      view.columns ||= [] if view.view
    end

    def validate_view_columns!(view)
      return unless view.view.blank? && view.columns.empty?

      raise ArgumentError, "no columns defined for view '#{view.name}'"
    end

    UserSettings.class_eval do
      user_attr :default_columns, :save_to_user, :named_views_method, :draggable,
                :named_views_position, :named_views_selector, :default_view,
                :unnamed_view_security_method, :global_views

      def label
        @conf.label(core: core)
      end
    end
  end
end
