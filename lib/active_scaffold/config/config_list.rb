module ActiveScaffold::Config
  class ConfigList < Base
    self.crud_type = :read
    def initialize(*args)
      super
      @link = self.class.link.clone unless self.class.link.nil?
      @save_to_user = self.class.save_to_user
      @draggable = self.class.draggable
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

    # enable draggable lists to select displayed columns (enabled by default)
    cattr_accessor :draggable
    self.draggable = true

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label
      @label ? as_(@label) : as_(:config_list_model, :model => @core.label(:count => 1))
    end

    # if you do not want to show all columns as a default you may define some
    # e.g. conf.config_list.default_columns = [:name, founded_on]
    attr_accessor :default_columns

    # configures the method in user model to save list configuration for every controller
    attr_accessor :save_to_user

    # enable draggable lists to select displayed columns
    attr_accessor :draggable

    # provides access to the list of columns specifically meant for the config_list to use
    columns_accessor :columns do
      columns.exclude :created_on, :created_at, :updated_on, :updated_at, :as_marked
      columns.exclude *@core.columns.select{|c| c.association.try(:polymorphic?)}.map(&:name)
    end
    
    # the ActionLink for this action
    attr_accessor :link
  end
end
