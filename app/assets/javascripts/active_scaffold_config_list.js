jQuery(document).ready(function () {
    jQuery(document).on('change', '.config-list-views[data-remote]', function () {
        jQuery(this).closest('form').submit();
    })
    jQuery(document).on('ajax:success', '.config-list-views', function () {
        var form = jQuery(this), link = form.parent().find('.actions [data-action="show_config_list"]'),
            href = new URL(link.attr('href'), window.location.origin);
        href.searchParams.set('config_list_view', form.find('select,input[checked]').val());
        link.attr('href', href.toString());
    })
    jQuery(document).on('input', '.show_config_list-view [name="config_list_view_name"]', function () {
        var field = jQuery(this),
          rename = field.parent().find('.rename-view'),
          global = field.parent().find('.global-view');
        if (field.val() !== field.attr('value')) rename.show();
        else rename.hide();
        if (field.val().trim()) global.show();
        else global.hide();
    })
});