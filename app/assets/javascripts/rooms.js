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

  // $('.join-room-btn').on('click', function() {
  //   $(this).attr('disabled', true);
  //   $(this).addClass('disabled');
  //   $(this).addClass('loading');
  // });

  var controller = $("body").data('controller');
  var action = $("body").data('action');

  if (controller === 'scheduled_meetings' && action === 'wait') {
    var room = $('#wait-for-moderator').data('room-id');
    var meeting = $('#wait-for-moderator').data('meeting-id');

    if (cable === 'true') {
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
    }
  }
});
