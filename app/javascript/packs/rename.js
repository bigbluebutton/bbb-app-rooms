/* 
 *  BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
 *  
 *  Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
 *  
 *  This program is free software; you can redistribute it and/or modify it under the
 *  terms of the GNU Lesser General Public License as published by the Free Software
 *  Foundation; either version 3.0 of the License, or (at your option) any later
 *  version.
 *  
 *  BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 *  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *  
 *  You should have received a copy of the GNU Lesser General Public License along
 *  with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
 */

$(document).on('turbolinks:load', function () {
  var controller = $("body").data('controller');
  var action = $("body").data('action');

  if (controller == "rooms" && action == "show" || controller == "rooms" && action == "update") {

    // Set a recording row rename event
    var configure_recording_row = function (recording_text) {

      function register_recording_text_event(e) {
        // Remove current window events
        $(window).off('mousedown keydown');

        // Toggle text to input using jquery.
        let $el = recording_text.find('text');
        let $input = $('<input type="text"/>').val($el.text().trim()).attr('id', $el.attr('id')).attr('class', $el.attr('class'));
        $el.replaceWith($input);

        var save = function () {
          let $text = $('<text/>').text($input.val()).attr('class', $input.attr('class'));
          $input.replaceWith($text);
          submit_rename_request(recording_text);
        };

        $input.on('blur keyup', function (e) {
          if (e.type === 'blur' || e.keyCode === 13) { // keycode is depreciated by still recognized by browsers, it's alt (.key) doesnt work in firefox
            save();
          }
        });
      }

      recording_text.find('a').on('click', function (e) {
        register_recording_text_event(e);
      });
    }

    // Apply ajax request depending on the element that triggered the event
    var submit_rename_request = function (element) {
      if (element.is('#recording-title')) {
        submit_update_request({
          setting: "rename_recording",
          record_id: element.data('recordid'),
          record_name: element.find('text').text(),
          launch_nonce: element.data('launch-nonce'),
        });
      }
      else if (element.is('#recording-description')) {
        submit_update_request({
          setting: "describe_recording",
          record_id: element.data('recordid'),
          record_description: element.find('text').text(),
          launch_nonce: element.data('launch-nonce'),
        });
      }
    }

    // Helper for submitting ajax requests
    var submit_update_request = function (data) {
      $.ajax({
        url: window.location.pathname + '/recording/' + data['record_id'] + '/update?launch_nonce=' + data['launch_nonce'],
        type: "POST",
        beforeSend: function (xhr) {
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
        },
        data: data,
        success: function (response) {
          console.log("succesfully updated. data = ", data);
        },
        error: function (xhr, status, error) {
          console.log("error in sending ajax request to rename recording");
        }
      });
    }


    var recording_rows = $('#recording-table').find('tr');

    // Configure renaming for recording rows
    recording_rows.each(function () {
      var recording_title = $(this).find('#recording-title');
      var recording_description = $(this).find('#recording-description');
      configure_recording_row(recording_title);
      configure_recording_row(recording_description);
    });
  }
});
