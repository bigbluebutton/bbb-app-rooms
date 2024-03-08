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

import '../channels/consumer'

$(document).on('turbolinks:load', function(){

  var controller = $("body").data('controller');
  var action = $("body").data('action');
	var chosenRoomId = $("#body").data("chosenroomid");
	
  if (!(controller == "rooms" && action == "meeting_join")){
    App.meetingInfo = App.cable.subscriptions.create({
        channel: "MeetingInfoChannel", 
        room_id: chosenRoomId
      }, {
      connected: function() {
        console.log("Connected to meeting info channel");
      },
      disconnected: function() {
        console.log("Disconnected from meeting info channel");
      },
      received: function(data) {
        console.log("Received data from meeting info channel. data: " + JSON.stringify(data));
        if (data.meeting_in_progress == true){
          startTime = data.elapsed_time
          start_elapsed_time();
          display_participant_count(data.participant_count);
          show_elems(); 
        }
        if (data.action == "end"){
          hide_elements();          
        }
      }
    });
  }
});

var startTime = 0;

var show_elems = function(){
  $('#end-meeting-btn').show();
  $('#meeting-info-msg').show();
  $('#wait-for-mod-msg').hide();
}

var hide_elements = function(){
  $('#end-meeting-btn').hide();
  $('#meeting-info-msg').hide();
  $('#wait-for-mod-msg').hide();
}

var display_participant_count = function(participantCount){
  if (participantCount == 1){
    var pplprson = "person";
  } else {
    var pplprson = "people";
  }
  document.getElementById('num-ppl-in-meeting-elem').innerHTML = participantCount;
  document.getElementById('ppl-or-person-elem').innerHTML = pplprson;
}

var start_elapsed_time = function(){
  var diff = new Date() - new Date(startTime); // the elapsed time in ms

  var secs = Math.floor((diff / 1000) % 60);
  var mins = Math.floor((diff / (60 * 1000)) % 60);
  var hrs = Math.floor((diff / (60 * 60 * 1000)) % 60);

  mins = addZeroMaybe(mins);
  secs = addZeroMaybe(secs);
  hrs = addZeroMaybe(hrs);

  document.getElementById('elapsed-time-elem').innerHTML =  hrs + ":" + mins + ":" + secs;

  setTimeout(start_elapsed_time, 500);
}

// If the time is less than 10 add a 0 in front of it
function addZeroMaybe(x) {
  if (x < 10) {
    x = "0" + x;
  }
  return x;
}
