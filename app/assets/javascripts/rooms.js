// BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
//
// Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
//
// This program is free software; you can redistribute it and/or modify it under the
// terms of the GNU Lesser General Public License as published by the Free Software
// Foundation; either version 3.0 of the License, or (at your option) any later
// version.
//
// BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License along
// with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

$(document).on('turbolinks:load', function(){

  var isInt = function(value) {
    return !isNaN(value) &&
    parseInt(Number(value)) == value &&
      !isNaN(parseInt(value, 10));
  };

  var controller = $("body").data('controller');
  var action = $("body").data('action');
  var cable = $("body").data('use-cable');

  if (controller === 'scheduled_meetings' && action === 'wait') {
    var room = $('#wait-for-moderator').data('room-id');
    var meeting = $('#wait-for-moderator').data('meeting-id');

    if (cable === true) {
      console.log('Setting up the websocket');
      App.cable.subscriptions.create({
        channel: "WaitChannel",
        room: room,
        meeting: meeting
      }, {
        connected: function(data) {
          console.log("connected");
        },
        disconnected: function(data) {
          console.log("disconnected");
          console.log(data);
        },
        rejected: function() {
          console.log("rejected");
        },
        received: function(data) {
          console.log("received", data);
          if (data['action'] === 'started') {
            console.log("submitting form");
            $('#wait-for-moderator').find('form [type=submit]').addClass('disabled');
            $('#wait-for-moderator').find('form').submit();
          }
        }
      });
    } else {
      var timeout = $('#wait-for-moderator').data('btn-timeout');
      timeout = parseInt(timeout) || 0;
      if (!isInt(timeout) || timeout <= 5000) {
        timeout = 60000;
      }
      console.log('Setting up retry button in', timeout);

      $('#wait-for-moderator-back').show();
      setTimeout(function() {
        console.log('Enabling retry button');
        $('#wait-for-moderator-back .btn').attr('disabled', null);
        $('#wait-for-moderator-back .btn').removeClass('disabled');
        $('#wait-for-moderator-back form').submit(function(e) {
          e.preventDefault();
          this.submit();
          $('.btn', this).addClass('disabled');
          $('.btn', this).attr('disabled', 'disabled');
        });
      }, timeout);
    }
  }
});
