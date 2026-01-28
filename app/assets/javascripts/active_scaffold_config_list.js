jQuery(document).ready(function () {
    jQuery(document).on('change', '.config-list-views[data-remote]', function () {
        jQuery(this).closest('form').submit();
    });
    jQuery(document).on('ajax:success', '.config-list-views', function () {
        var form = jQuery(this), link = form.parent().find('.actions [data-action="show_config_list"]'),
            href = new URL(link.attr('href'), window.location.origin);
        href.searchParams.set('config_list_view', form.find('select,input[checked]').val());
        link.attr('href', href.toString());
    });
    jQuery(document).on('input', '.show_config_list-view [name="config_list_view_name"]', function () {
        var field = jQuery(this),
            rename = field.parent().find('.rename-view'),
            global = field.parent().find('.global-view'),
            global_hidden = global.find('input[type=hidden]'),
            global_cb = global.find('input[type=checkbox]'),
            rename_cb = rename.find('input[type=checkbox]');
        if (field.val().trim()) global.show();
        else global.hide();
        if (field.val() !== field.attr('value')) {
            rename.show();
            global_hidden.prop('disabled', rename_cb.length ? !rename_cb.prop('checked') : true);
            global_cb.prop('disabled', rename_cb.length ? rename_cb.prop('checked') : false);
        } else {
            rename.hide();
            rename_cb.prop('checked', false);
            global_hidden.prop('disabled', false);
            global_cb.prop('disabled', true);
            global_cb.prop('checked', global_hidden.val() === '1');
        }
    });
    jQuery(document).on('change', '.show_config_list-view .rename-view input[type=checkbox]', function () {
        var rename_cb = jQuery(this),
            global = rename_cb.closest('.form-element').find('.global-view'),
            global_hidden = global.find('input[type=hidden]'),
            global_cb = global.find('input[type=checkbox]');
        global_hidden.prop('disabled', !rename_cb.prop('checked'));
        global_cb.prop('disabled', rename_cb.prop('checked'));
        if (global_cb.prop('disabled')) global_cb.prop('checked', global_hidden.val() === '1');
    });
});