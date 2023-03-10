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
    var room = window.location.pathname.split('/')[3];
   
    var controller = $("body").data('controller');
    var action = $("body").data('action');
    if (controller == "rooms" && action == "meeting_join"){
        var personal_join_link = $("body").data('meeting');
        App.waiter = App.cable.subscriptions.create({
            channel: "WaitChannel",
            room_id: room
        }, {
            connected: function(data) {
                console.log("connected to wait");
            },
            disconnected: function(data) {
                console.log("disconnected to wait");
                console.log(data);
            },
            received: function(data) {
                console.log("This is the wait data: " + JSON.stringify(data));
                if (data.action == "started"){
                    $('#wait-for-mod-msg').hide();
                    window.location.replace(personal_join_link);
                    this.perform("notify_join");
                    this.unsubscribe();                                
                }
            }
        })
    }
   
    $('#end-meeting-btn').on('click', function() {
        var end_meeting_url = $(this).data('url');

        $.ajax({
            url: end_meeting_url,
            type: "POST",
            beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
            data: "",
        });
    })
});
