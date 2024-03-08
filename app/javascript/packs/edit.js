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
    $('#copy-icon-group').on('click', function() {
        let useSharedCodeCheckbox = $('#use_shared_code_checkbox');
        let inputField = $('#shared_code_field');

        inputField.removeAttr('disabled');
        inputField.select();
        document.execCommand('copy');
        window.getSelection().removeAllRanges();
        if (!useSharedCodeCheckbox.prop('checked')) {
            inputField.attr('disabled', 'true');
        }

        let copyIcon = $('.copy-icon');
        copyIcon.css('display', 'none');
        let checkIcon = $('.check-icon');
        checkIcon.css('display', 'inline-block');
        let copiedText = $('#copied-text');
        copiedText.css('display', 'inline');

        setTimeout(function() {
            checkIcon.css('display', 'none');
            copyIcon.css('display', 'inline-block');
            copiedText.css('display', 'none');
        }, 2000);
    })

    $('#use_shared_code_checkbox').on('click', function() {
        var textAreas = $('.check-disabled');
        var elements = $('.lock-visibility');
        var use_shared_code_checked = $('#use_shared_code_checkbox').prop("checked");
        if (use_shared_code_checked) {
            textAreas.prop('disabled', true);
            textAreas.addClass('disabled-textarea');
            elements.css('display', 'inline');
        } else {
            textAreas.prop('disabled', false);
            textAreas.removeClass('disabled-textarea');
            elements.css('display', 'none');
        }
    });

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

    // If shared room is selected, allow the code field to be editable
    $('#use_shared_code_checkbox').on('click', function() {
        var use_shared_code_checked = $('#use_shared_code_checkbox').prop("checked");
        if (use_shared_code_checked){
            $('#shared_code_field').prop("disabled", false);
            $('#shared_code_field').val('');
        } else {
            $('#shared_code_field').prop("disabled", true);
            console.log("code_val: = ",$('#room_code_value').val() )
            $('#shared_code_field').val($('#room_code_value').val());
        }
    })

		function checkSharedCodeCheckboxStatus() {
			var sharedcode_checked = $('#use_shared_code_checkbox').prop("checked");
        if (!sharedcode_checked){
					$('#shared_code_field').prop("disabled", true);
				} else {
					$('#shared_code_field').prop("disabled", false);
				}
		}

		checkSharedCodeCheckboxStatus();


});
