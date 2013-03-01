module ActiveScaffold::Config
  class ConfigList < Base
    self.crud_type = :read
    def initialize(*args)
      super
      @link = self.class.link.clone unless self.class.link.nil?
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
    @@plugin_directory = File.expand_path(__FILE__).match(%{(^.*)/lib/active_scaffold/config/config_list.rb})[1]

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label
      @label ? as_(@label) : as_(:config_list_model, :model => @core.label.singularize)
    end

    # if you do not want to show all columns as a default you may define some
    # e.g. conf.config_list.default_columns = [:name, founded_on]
    attr_accessor :default_columns

    # provides access to the list of columns specifically meant for the config_list to use
    def columns
      unless @columns # lazy evaluation
        self.columns = @core.columns._inheritable
        self.columns.exclude :created_on, :created_at, :updated_on, :updated_at, :as_marked
        self.columns.exclude *@core.columns.collect{|c| c.name if c.polymorphic_association?}.compact
      end
      @columns
    end
    
    public :columns=
    
    # the ActionLink for this action
    attr_accessor :link
  end
end
