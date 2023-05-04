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

    $('#allModerators_checkbox').on('click', function() {
        var all_mod_checked = $('#allModerators_checkbox').prop("checked");
        if (all_mod_checked){
            $('#waitForModerator_checkbox').prop("checked", false);
        }
    })

    $('#waitForModerator_checkbox').on('click', function() {
        var wait_mod_checked = $('#waitForModerator_checkbox').prop("checked");
        if (wait_mod_checked){
            $('#allModerators_checkbox').prop("checked", false);
        }
    })

   

    function check_record_status(){
        var record_checked = $('#record_checkbox').prop("checked");
        if (!record_checked){
            $('#allowStartStopRecording_checkbox').prop("checked", false);
            $('#allowStartStopRecording_checkbox').prop("disabled", true);
            $('#autoStartRecording_checkbox').prop("checked", false);
            $('#autoStartRecording_checkbox').prop("disabled", true);
        } else {
            $('#allowStartStopRecording_checkbox').prop("disabled", false);
            $('#autoStartRecording_checkbox').prop("disabled", false);
        }
    }
    
    check_record_status(); // check status every time page is loaded

    $('#record_checkbox').on('click', function() {
        check_record_status();
    })
});
