This works with Rails >= 5.2 and ActiveScaffold >= 3.7.1  
Version 3.4.x and 3.5.x worked with Rails >= 4.0 and ActiveScaffold >= 3.4.4  
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
  config.config_list.save_to_user = :config_list_for
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
class User < ApplicationRecord
  has_many :list_configurations
  def config_list_for(controller_id, controller_name)
    # Use controller_id to allow having different columns on different nested or embedded conditions
    list_configurations.where(controller_id: controller_id).first_or_initialize
    # Or use controller_name for one configuration for the controller, even embedded or nested
    list_configurations.where(controller_id: controller_name).first_or_initialize
  end
end
```

## Named Views

It's possible to define named views, with a set of columns, so users can switch between default view and other defined views. Adding a view is done with `add_view` method, and passing a name (symbol or string) and an array of columns:

```rb
conf.config_list.add_view :simple, [:number, :status]
```

Although it's possible to use a block too, to change other view settings, such as label, sorting and security method. If the label is set, it can be a string, or a symbol to be localized, and the name is used in the URL parameters. When using a block, the columns can be defined in the view instead of the `add_view` call:

```rb
conf.config_list.add_view :simple do |view|
  view.label = 'Number and Status'
  view.columns = [:number, :status]
  view.sorting = {number: :desc}
  view.security_method = :simple_view_authorized?
end
```

The columns defined in the view are not required to be in the `conf.list.columns`, so it's possible to add views including columns that are not available in the normal config list.

The security method is a controller method used to check if the view is available for the user, it must return true when the view is allowed:

```rb
def simple_view_authorized?
  current_user.is_admin?
end
```

When a named view is selected, the configure action link is not rendered.

The view selector is displayed in the title header, and it's rendered as a menu of links, displaying the selected view, and the list of available views on hover. The selector can be changed to a list of radio buttons or select field with `conf.config_list.named_views_selector`,per controller, or it can be changed globally in `ActiveScaffold.defaults`:

```rb
conf.config_list.named_views_selector = :radio  # use radio buttons
conf.config_list.named_views_selector = :select # use select field
conf.config_list.named_views_selector = :links  # use a menu of links (default)
```

The position of the views selector can be changed with `conf.config_list.named_views_position`, setting it to `:center` (default, between the title and actions), `:left` (next to the title) or `:right` (at the right of the actions). Although the position of the `div.config-list-views` doesn't change, it just adds a class (center, right or left) and use CSS of flexbox layout to change the position (changing `flex-grow` and `order`). It can be changed per controller or globally in `ActiveScaffold.defaults`:

```rb
conf.config_list.named_views_position = :center
conf.config_list.named_views_position = :left
conf.config_list.named_views_position = :right
```

## Saving Named Views

It's possible to save the configured columns and sorting with a name, and change between default view, named views defined in the config and user named views. Config list will have a field to set the name, when no name is set, it's saved as normal config list, overriding the default view.

When a user named view is selected, configure will open the form with that view's settings. If the name is changed, a checkbox will show up allowing to rename the current view. Submitting the form without checking that checkbox will create a new named view, and will rename the current view if the checkbox is selected. In this case, it isn't possible to override the default view, clearing the view's name won't be allowed.

Also, when a user named view is selected, the config list form will have a delete link instead of reset link.

![screenshot](./images/config-named-view.png)

Enabling this feature requires to enable saving views to the DB, with `conf.config_list.save_to_user`, as it will use the same method to get the named view, and set another method in `conf.config_list.named_views_method`. Both options can be set per controller, or globally in `ActiveScaffold.defaults`.

Then, the method in `save_to_user` must accept options with double splat (or keyword arguments `view_name` and `attributes`), and it's responsible to look for a named view for the user, using view_name or slug argument, and return a new model when none is found. Also it's responsible to set the view_name from opts[:attributes] (or `attributes` keyword arg) in the right column. It can use the same model as saving default view without name. When selecting the default view, and saving it, the keyword arguments will be nil.

```rb
ActiveScaffold.defaults do |config|
  config.config_list.save_to_user = :config_list_for
end

class User < ApplicationRecord
  has_many :list_configurations
  def config_list_for(controller_id, controller_name, **opts)
    list_configurations.where(controller_id: controller_name, view_name: opts[:view_name]).first_or_initialize.tap { |r| r.view_name == opts[:attributes][:view_name] if opts[:attributes] }
  end
end
```

The method in `named_views_method` must return an array with the saved named views for the user, and each item will be an array with the label and name in URL parameter (for example, `view_name` and `slug` columns), or just a string to use for both label and name. This method will receive `controller_id` and `controller_name` arguments, just like the method in `save_to_user`.


```rb
ActiveScaffold.defaults do |config|
  config.config_list.named_views_method = :config_list_views
end

class User < ApplicationRecord
  has_many :list_configurations
  def config_list_views(controller_id, controller_name)
    list_configurations.where(controller_id: controller_name).where.not(view_name: nil).pluck(:view_name)
  end
end
```
## Global Views

It's possible to define global views, so they are available to all users. It's enabled with `conf.config_list.global_views`, and requies to use `save_to_user` and `named_views_method` too, as they work as saved named views.

These views require to have a name, when a name is typed, global view checkbox will show up. It requires another column, `slug`, as there may be a name collision, and it's hard to prevent, because it's weird to forbid creating a global view with a name, because some other user already used it for a private view. Then, the method configured in `save_to_user` will get another keyword argument, `slug`, or use double splat. The slug will be built prefixing the view name with `user-` or `global-`.

The method configured in `save_to_user` must look for user views when the slug starts with `user-`, and ensure the user_id is set (for example using the association):

```rb
def config_list_for(controller_id, controller_name, slug: nil, attributes: nil)
  query = list_configurations
  query = UserListConfiguration.where(user_id: nil).or(list_configurations) unless slug.to_s.start_with?('user-')
  query.where(controller_id: controller_name, slug: slug).first_or_initialize.tap do |record|
    record.attributes = attributes if attributes
  end
end
```

And the method configured in `named_views_method` should return the view name and the slug, so user see the view name, and slug is used in the URL:

```rb
def config_list_views(controller_id, controller_name)
  list_configurations.or(UserListConfiguration.where(user_id: nil)).where.not(slug: nil).pluck(:view_name, :slug)
end
```

It's possible to user other column names than `view_name` and `slug`, just ensure the values are set from `attributes[:view_name]` and `attributes[:slug]`, and use the right column names in the queries.

If you want to override a global view with a private view having the same name, so user don't see 2 options with the same name in the views selector, get uniq views by name:

```rb
def config_list_views(controller_id, controller_name)
  list_configurations.or(UserListConfiguration.where(user_id: nil)).
    where.not(slug: nil).where(controller_id: controller_name).
    pluck(:view_name, :slug).uniq { |(name, _)| name }
end
```

If you want to change how slugs are built globally, you can define a method in ApplicationController, and configure it with `conf.config_list.slug_builder` in `ActiveScaffold.defaults`. It's a global setting only, can't be set per controller. To customize slug builder in a controller, define `config_list_slug` in the controller. The `config_list_slug` method, and the slug builder method, will get the view name and global_view boolean, and must return the slug. It's called when saving a view.

When editing a view, global checkbox can be changed only if a new view is going to be created (the name of the view is changed, and rename is unchecked). 