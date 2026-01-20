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
    end

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    def self.link
      @@link
    end
    def self.link=(val)
      @@link = val
    end
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show_config_list', :label => :config_list, :type => :collection, :security_method => :config_list_authorized?)

    # configures where the plugin itself is located. there is no instance version of this.
    cattr_accessor :plugin_directory
    self.plugin_directory = File.expand_path(__FILE__).match(%{(^.*)/lib/active_scaffold/config/config_list.rb})[1]

    # configures the method in user model to save list configuration for every controller
    cattr_accessor :save_to_user

    # configures the method in user model to return the named views saved for the user,
    # setting it enables saving the views, but requires to set a method in save_to_user
    cattr_accessor :named_views_method

    # the position to place the named views selector, :left (next to the title),
    # :right or :center (default, before the actions and filters)
    cattr_accessor :named_views_position
    @@named_views_position = :center

    # the type of selector for named views, :links, :select or :radio
    cattr_accessor :named_views_selector
    @@named_views_selector = :links

    # enable draggable lists to select displayed columns (enabled by default)
    cattr_accessor :draggable
    self.draggable = true

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label(core: @core)
      @label ? as_(@label) : as_(:config_list_model, :model => core.label(:count => 1))
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

    # generic named views
    attr_accessor :named_views

    # enable draggable lists to select displayed columns
    attr_accessor :draggable

    # provides access to the list of columns specifically meant for the config_list to use
    columns_accessor :columns do
      columns.exclude :created_on, :created_at, :updated_on, :updated_at, :as_marked
      columns.exclude *@core.columns.select{|c| c.association.try(:polymorphic?)}.map(&:name)
    end
    
    # the ActionLink for this action
    attr_accessor :link

    UserSettings.class_eval do
      user_attr :default_columns, :save_to_user, :named_views_method, :draggable,
                :named_views_position, :named_views_selector

      def label
        @conf.label(core: core)
      end
    end
  end
end
