$(document).on('turbolinks:load', function(){
  var room = window.location.pathname.split('/')[3];
  App.meetingInfo = App.cable.subscriptions.create({channel: "MeetingInfoChannel", room_id: room}, {
    connected: function() {
        console.log("Connected to meeting info channel");
    },
    disconnected: function() {
    },
    received: function(data) {
      console.log("received data: " + JSON.stringify(data));
      if (data.meeting_in_progress == true){
        startTime = data.elapsed_time
        in_progress = true;
        start_elapsed_time();
        display_participant_count(data.participant_count);
        show_elems(); 
      }
      if (data.action == "end"){
        in_progress = false;
        hide_elements();          
      }
    }
  });
});

var startTime = 0;
var in_progress = false;

var show_elems = function(){
  $('#end-meeting-btn').show();
  $('#meeting-info-msg').show();
}

var hide_elements = function(){
  $('#end-meeting-btn').hide();
  $('#meeting-info-msg').hide();
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
