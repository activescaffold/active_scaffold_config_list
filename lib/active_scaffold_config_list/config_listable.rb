# frozen_string_literal: true

module ActiveScaffoldConfigList
  # app/models/concerns/config_listable.rb
  module ConfigListable
    extend ActiveSupport::Concern

    class_methods do
      def has_config_lists(model_name,
                           association_name: :list_configurations,
                           association_options: {},
                           view_name_column: :view_name,
                           slug_column: :slug,
                           controller_column: :controller_id,
                           controller_matcher: :controller_name)
        # Define the association
        class_eval do
          has_many association_name, class_name: model_name, **association_options
        end

        model_class = model_name.to_s.classify.constantize
        view_name_column = nil unless model_class.column_names.include?(view_name_column.to_s)
        slug_column = nil unless model_class.column_names.include?(slug_column.to_s)

        self.config_list_settings = {
          association_name: association_name,
          model_name: model_name,
          view_name_column: view_name_column,
          slug_column: slug_column,
          controller_column: controller_column,
          model_class: model_class,
          foreign_key: reflect_on_association(association_name).foreign_key,
          controller_matcher: controller_matcher
        }.freeze

        # Include instance methods
        include ConfigListable::InstanceMethods unless included_modules.include?(ConfigListable::InstanceMethods)
      end
    end

    included do
      class_attribute :config_list_settings, instance_writer: false, default: nil
    end

    module InstanceMethods
      def config_list_for(controller_id, controller_name, view_name: nil, slug: nil, attributes: nil)
        settings = self.class.config_list_settings
        query = list_configurations_query(controller_id, controller_name, user_views: slug.nil? || slug.to_s.start_with?('user-'))

        if slug
          query = query.where(settings[:slug_column] => slug)
        elsif view_name
          query = query.where(settings[:view_name_column] => view_name)
        else
          column = settings[:slug_column] || settings[:view_name_column]
          query = query.where(column => nil) if column
        end

        query.first_or_initialize.tap do |record|
          record.attributes = map_attribute_names(attributes, settings) if attributes
        end
      end

      def config_list_views(controller_id, controller_name)
        settings = self.class.config_list_settings
        list_configurations_query(controller_id, controller_name)
          .where.not(settings[:view_name_column] => nil)
          .pluck([settings[:view_name_column], settings[:slug_column]].compact)
      end

      private

      def determine_controller_value(controller_id, controller_name, settings)
        matcher = settings[:controller_matcher]

        case matcher
        when :controller_id
          {settings[:controller_column] => controller_id}
        else
          # Default to controller_id if matcher is a callable
          if matcher.respond_to?(:call)
            matcher.call(controller_id, controller_name)
          else
            # Fallback to controller_name
            {settings[:controller_column] => controller_name}
          end
        end
      end

      def list_configurations_query(controller_id, controller_name, user_views: true)
        settings = self.class.config_list_settings
        query = send(settings[:association_name])
        # Add the OR condition if user_views is false
        query = settings[:model_class].where(settings[:foreign_key] => nil).or(query) unless user_views
        query.where(determine_controller_value(controller_id, controller_name, settings))
      end

      def map_attribute_names(attributes, settings)
        return attributes unless attributes.is_a?(Hash)

        attributes.symbolize_keys.transform_keys do |key|
          case key
          when :view_name then settings[:view_name_column]
          when :slug then settings[:slug_column]
          else
            key
          end
        end
      end
    end
  end
end
