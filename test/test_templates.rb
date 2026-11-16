# frozen_string_literal: true

require 'test_helper'

class ConfigListTemplatesTest < Minitest::Test
  VIEW_PATH = File.expand_path('../app/views', __dir__)
  LOOKUP_CONTEXT = ActionView::LookupContext.new([VIEW_PATH])

  ConfigList = Struct.new(
    :named_views_position,
    :named_views_selector,
    :draggable,
    :label,
    keyword_init: true
  )
  Config = Struct.new(:config_list)
  NamedView = Struct.new(:view)
  Column = Struct.new(:name, :label, :sortable) do
    def sortable?
      sortable
    end
  end

  class ViewContext < ActionView::Base
    attr_accessor :columns_enabled, :global_views_enabled, :named_view, :named_views_enabled,
                  :params, :saved_columns, :saved_sorting, :sorting_enabled
    attr_reader :active_scaffold_config, :render_calls

    def initialize(lookup_context, assigns, controller)
      super
      @active_scaffold_config = Config.new(
        ConfigList.new(
          named_views_position: :center,
          named_views_selector: :links,
          draggable: true,
          label: 'Configure list'
        )
      )
      @columns_enabled = true
      @global_views_enabled = true
      @named_views_enabled = true
      @sorting_enabled = true
      @params = {config_list_view: 'daily'}
      @saved_columns = %i[name status]
      @saved_sorting = [%i[status desc]]
      @render_calls = []
    end

    def render_root(options)
      @render_root = true
      render(options)
    ensure
      @render_root = false
    end

    def render(options = {}, locals = {}, &)
      if @render_root
        @render_root = false
        super
      else
        render_calls << [options, locals]
        ActiveSupport::SafeBuffer.new("[rendered #{options}]")
      end
    end

    def as_element(_name, content = nil, **, &block)
      content = capture(&block) if block
      ActiveSupport::SafeBuffer.new(content.to_s)
    end

    def as_element_attributes(_name, **options)
      options
    end

    def as_(key, **options)
      options.empty? ? key.to_s : "#{key}:#{options.values.join(',')}"
    end

    def params_for(**options)
      options
    end

    def url_for(options)
      "/records/#{options[:action]}"
    end

    def form_tag(*, **, &)
      capture(&)
    end

    def active_scaffold_named_view_selector
      'view selector'
    end

    def config_list_named_views?
      named_views_enabled
    end

    def config_list_columns?
      columns_enabled
    end

    def config_list_sorting?
      sorting_enabled
    end

    def config_list_save_named_views?
      named_views_enabled
    end

    def config_list_global_views?
      global_views_enabled
    end

    def config_list_columns
      [['Name', :name], ['Status', :status]]
    end

    def config_list_params
      saved_columns
    end

    def config_list_sorting
      saved_sorting
    end

    def list_columns
      [Column.new(:name, 'Name', true), Column.new(:status, 'Status', true)]
    end

    def element_form_id(action:)
      "records-#{action}"
    end

    def active_scaffold_checkbox_list(*arguments, **options)
      "checkboxes:#{arguments.inspect}:#{options.inspect}"
    end

    def form_attribute_html(_column, label, content, *)
      "#{label}:#{content}"
    end

    def active_scaffold_input_text_options(**options)
      options
    end
  end

  CompiledViewContext = ViewContext.with_empty_template_cache

  def setup
    @view = CompiledViewContext.new(
      LOOKUP_CONTEXT,
      {config_list_view_name: 'Daily', global_view: true},
      nil
    )
  end

  def test_executes_list_header_form_and_field_partials
    @view.named_view = NamedView.new('calendar')

    %w[
      list
      list_header
      show_config_list_columns
      show_config_list_form
      show_config_list_form_body
      show_config_list_named_view
      show_config_list_sorting
      show_config_list_sorting_fields
    ].each { |name| render_partial(name) }

    render_template('show_config_list_form')

    assert(@view.render_calls.any? { |options, _| options == 'calendar' })
    assert(@view.render_calls.any? { |options, _| options == 'show_config_list_columns' })
    assert(@view.render_calls.any? { |options, _| options == 'show_config_list_sorting_item' })
  end

  def test_named_views_support_link_and_form_selectors
    output = render_partial('named_views')

    assert_includes output, 'view selector'

    @view.active_scaffold_config.config_list.named_views_selector = :radio
    output = render_partial('named_views')

    assert_includes output, 'view selector'
  end

  def test_named_view_fields_support_existing_new_and_global_views
    output = render_partial('show_config_list_named_view_fields')

    assert_includes output, 'config_list_old_view_name'
    assert_includes output, 'global_view'

    @view.assign({config_list_view_name: nil, global_view: false})
    output = render_partial('show_config_list_named_view_fields')

    refute_includes output, 'config_list_old_view_name'

    @view.global_views_enabled = false
    output = render_partial('show_config_list_named_view_fields')

    refute_includes output, 'global_view'
  end

  def test_sorting_item_renders_column_and_direction_selects
    output = render_partial(
      'show_config_list_sorting_item',
      index: 0,
      columns_options: [['Status', :status]],
      order_options: [%w[Descending desc]],
      selected: [%i[status desc]]
    )

    assert_includes output, 'config_list_sorting[0][]'
    assert_includes output, 'selected="selected"'
  end

  private

  def render_partial(name, locals = {})
    @view.render_root(partial: "active_scaffold_overrides/#{name}", locals: locals)
  end

  def render_template(name)
    @view.render_root(template: "active_scaffold_overrides/#{name}")
  end
end
