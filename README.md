This works with Rails >= 4.0 and ActiveScaffold >= 3.4.4
Version 3.3.x worked with Rails 3.2 and ActiveScaffold >= 3.4.4
Version 3.2.x worked with Rails 3.2 and ActiveScaffold >= 3.3.0

Usage:

```rb
active_scaffold :model do |conf|
  conf.actions.add :config_list
end
````


Overview
========

A plugin for Active Scaffold that provides the ability to choose the column to show in the scaffold list at run-time.

You have the option of defining a default set of columns for the controller. For example:
```rb
config.config_list.default_columns = [:name, :project, :amount]
```
If this is not defined then active_scaffold_config.list.columns is used.

This is useful when you want the option to look at a potentially large number of columns but be able to 
easily reset back to something that fits on the screen without horizontal scrolling.

The available columns in the configure action are the columns defined in `list.columns`. For that reason, if
`config_list.default_columns` is not defined, then it will default to `list.columns`, and the users only will be able
to remove some columns, they won't be able to add other columns.

The configuration data will be saved on the session. It can be saved on the DB defining a method on the user model
(the one returned by current_user method) to return a record for current controller, or empty record if user has no
list configuration, and setting config_list to use that method.

```rb
conf.config_list.save_to_user = :config_list_for
```

It can be changed globally for the app in `ActiveScaffold.defaults` in an initializer, such as:

```rb
ActiveScaffold.defaults do |config|
  config.config_list.save_to_user
end
```

The model storing list configuration must have a config_list text column storing the columns list, and config_list_sort
serialized text column. For example:

```rb
# == Schema Information
#
# Table name: list_configurations
#
#  id                  :bigint           not null, primary key
#  config_list         :text
#  config_list_sorting :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  controller_id       :string(255)
#  user_id             :bigint
#
# Indexes
#
#  index_list_configurations_on_user_id  (user_id)
#

class ListConfiguration < ApplicationRecord
  belongs_to :user
  serialize :config_list_sorting, JSON
end
```

Then in the User model, define the association, and the method returning the config list for the requested controller.
The method has 2 arguments, `controller_id` and `controller_name`, so only need to save one of them, depending if user
configuration must be shared on different conditions for embedded controllers, and each parent for nested controllers,
or save unique configurations. The `controller_id` argument will be different in embedded controllers, nested controllers
and regular controllers, as it will use `active_scaffold_session_storage_key`, and the controller_name will be the same
always.

```rb
class User < ActiveRecord::Base
  has_many :list_configurations
  def config_list_for(controller_id, controller_name)
    # Use controller_id to allow having different columns on different nested or embedded conditions
    list_configurations.where(controller_id: controller_id).first_or_initialize
    # Or use controller_name for one configuration for the controller, even embedded or nested
    list_configurations.where(controller_id: controller_name).first_or_initialize
  end
end
```
