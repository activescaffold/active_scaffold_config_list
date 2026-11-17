# frozen_string_literal: true

require 'javascript_test_helper'

class ConfigListJavascriptTest < ActiveScaffold::TestSupport::Javascript::TestCase
  def fixture_html
    <<~HTML
      <script>
        jQuery(document).on('submit', '#views-form', function(event) {
          event.preventDefault();
          window.configListSubmitted = true;
        });
      </script>
      <div class="active-scaffold">
        <div>
          <form id="views-form" class="config-list-views" data-remote="true">
            <select id="view-select"><option value="mine">Mine</option><option value="all">All</option></select>
          </form>
          <div class="actions"><a data-action="show_config_list" href="/records?old=1">Configure</a></div>
        </div>
        <div class="show_config_list-view form-element">
          <input name="config_list_view_name" value="Original">
          <label class="rename-view" style="display:none"><input type="checkbox"></label>
          <label class="global-view"><input type="hidden" value="1"><input type="checkbox"></label>
        </div>
      </div>
    HTML
  end

  def test_submits_selection_updates_link_and_toggles_rename_controls
    visit_javascript_fixture

    select 'All', from: 'view-select'
    assert_javascript 'window.configListSubmitted === true'
    execute_script "jQuery('#views-form').trigger('ajax:success')"
    assert_javascript <<~JS
      new URL(document.querySelector('[data-action="show_config_list"]').href).searchParams.get('config_list_view') === 'all'
    JS

    fill_in 'config_list_view_name', with: 'Renamed'
    assert_javascript 'document.querySelector(".rename-view").style.display !== "none"'
    assert_javascript 'document.querySelector(".global-view input[type=checkbox]").disabled === false'
    assert_no_javascript_errors
  end
end
