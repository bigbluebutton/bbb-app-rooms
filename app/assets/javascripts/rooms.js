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

$(document).on('turbolinks:load', function(){
    $('#join-room-btn').on('click', function() {
        var join_room_url = $(this).data('url');
        var room_id = $(this).data('room');

        $.ajax({
            url: join_room_url,
            type: "POST",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
            data: "",
            success: function(data) {
                var meeting_url = data.meeting;
                if (data.wait_for_mod !== true) { 
                    window.open(meeting_url);
                } else {
                    $('#wait-for-mod-msg').show();

                    App.waiter = App.cable.subscriptions.create({
                        channel: "WaitChannel",
                        room: room_id
                    }, {
                        connected: function(data) {
                            console.log("connected to wait");
                        },
                        disconnected: function(data) {
                            console.log("disconnected to wait");
                            console.log(data);
                        },
                        rejected: function() {
                            console.log("rejected from wait");
                        },
                        received: function(data) {
                            console.log("This is the wait data: " + JSON.stringify(data));
                            if (data.action == "started"){
                                $('#wait-for-mod-msg').hide();
                                window.open(meeting_url);
                                this.perform("notify_join");
                                App.waiter.unsubscribe();
                            }
                        }
                    });
                }
                
            }
        });   
    })

    $('#end-meeting-btn').on('click', function() {
        var end_meeting_url = $(this).data('url');
        var room_id = $(this).data('room');

        $.ajax({
            url: end_meeting_url,
            type: "POST",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
            data: "",
        });
    })
});
