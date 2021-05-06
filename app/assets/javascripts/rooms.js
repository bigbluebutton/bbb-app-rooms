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
//= require './polling'

$(document).on('turbolinks:load', function(){

  var controller = $("body").data('controller');
  var action = $("body").data('action');
  var cable = $("body").data('use-cable');

  var pollStatus = function() {
    console.log('Checking if the meeting started');
    var url = $('#wait-for-moderator').data('wait-url');
    $.ajax({
      url: url,
      dataType: "json",
      contentType: "application/json",
      error: function() { console.log('Error checking'); },
      success: function(data) {
        console.log("received", data);
        if (data['running'] === true) {
          joinSession();
        }
      }
    });
  };

  var joinSession = function() {
    console.log("Joining session");
    $('#wait-for-moderator').find('form [type=submit]').addClass('disabled');
    $('#wait-for-moderator').find('form').submit();
  };

  if (controller === 'scheduled_meetings' && action === 'wait') {
    var room = $('#wait-for-moderator').data('room-id');
    var meeting = $('#wait-for-moderator').data('meeting-id');

    Polling.setPolling(pollStatus)
    
    var running = $('#wait-for-moderator').data('is-running');
    if (running === true) {
      console.log('Already running, joining soon');
      setTimeout(function() { joinSession(); }, 200);
      return;
    }

    var auto = $('#wait-for-moderator').data('auto');
    if (auto === true) {
      console.log('Auto joining in a few seconds');
      var delay = 2000 + Math.floor(Math.random()*1000);
      setTimeout(function() { joinSession(); }, delay);
      return;
    }

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
            joinSession();
          }
        }
      });
    }
  }
});
