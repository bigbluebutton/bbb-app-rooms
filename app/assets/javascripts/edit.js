$(document).on('turbolinks:load', function(){

    $('#all_mod_checkbox').on('click', function() {
        var all_mod_checked = $('#all_mod_checkbox').prop("checked");
        if (all_mod_checked){
            $('#wait_mod_checkbox').prop("checked", false);
        }
    })

    $('#wait_mod_checkbox').on('click', function() {
        var wait_mod_checked = $('#wait_mod_checkbox').prop("checked");
        if (wait_mod_checked){
            $('#all_mod_checkbox').prop("checked", false);
        }
    })
});
  