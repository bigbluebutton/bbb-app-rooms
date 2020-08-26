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
          console.log("meeting in progress")
          show_end_meeting_btn();
        }
        if (data.action == "end"){
          console.log("ended meeting");
          hide_end_meeting_btn();
          
        }
    }
  });
});

var show_end_meeting_btn = function(){
  $('#end-meeting-btn').show();
}

var hide_end_meeting_btn = function(){
  $('#end-meeting-btn').hide();
}