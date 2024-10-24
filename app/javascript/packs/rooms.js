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

$(document).on('turbolinks:load', function () {

    $('#end-meeting-btn').on('click', function () {
        var end_meeting_url = $(this).data('url');

        $.ajax({
            url: end_meeting_url,
            type: "POST",
            beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
            data: "",
        });
    })

    $('#revoke-code-btn').on('click', function () {
        var revoke_code_url = $(this).data('url');
        console.log("revoke_code_url = ", revoke_code_url)
        $.ajax({
            url: revoke_code_url,
            type: "POST",
            beforeSend: function (xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')) },
            data: "",
        });
    })



    var isFirefox = navigator.userAgent.indexOf("Firefox") != -1;
    var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || (typeof safari !== 'undefined' && window['safari'].pushNotification));


    /*
    With Dynamic State Partitioning enabled, Firefox provides embedded resources with a separate storage bucket for every top-level website, causing the request to be denied if it comes from a third party. Embedded third-parties may request access to the top-level storage bucket, which is what we're doing with the requestAccess() method.
    */
    if (isFirefox || isSafari) {
        document.hasStorageAccess().then((hasAccess) => {
            if (!hasAccess && (isFirefox || isSafari)) {
                $('#access-alert').show();
                console.log("no access");

            } else {
                console.log("Already has access");
            }
        });
    }

    /** PAGINATION STUFF */
    /** disable previous or next buttons if user is on first or last page */
    const $paginationContainer = $("#pagination-container");

    if ($paginationContainer.length) {
        const currentPage = parseInt($paginationContainer.data("current-page"));
        const totalPages = parseInt($paginationContainer.data("total-pages"));

        const $previousButton = $("#backbtn");
        const $nextButton = $("#nextbtn");

        // Disable Previous button if on the first page
        if (currentPage <= 1) {
            $previousButton.addClass("cursor-not-allowed opacity-50")
                .attr("aria-disabled", "true")
                .attr("href", "javascript:void(0)");
        } else {
            $previousButton.removeClass("cursor-not-allowed opacity-50")
                .removeAttr("aria-disabled")
                .attr("href", $previousButton.data("pageNum"));
        }

        // Disable Next button if on the last page
        if (currentPage >= totalPages) {
            $nextButton.addClass("cursor-not-allowed opacity-50")
                .attr("aria-disabled", "true")
                .attr("href", "javascript:void(0)");
        } else {
            $nextButton.removeClass("cursor-not-allowed opacity-50")
                .removeAttr("aria-disabled")
                .attr("href", $nextButton.data("pageNum"));
        }
    }

    /** change the colour of the page buttons */
    // Get the current page number from the container
    const currentPage = $("#pagination-container").data("current-page");

    // Define the classes
    const activeClasses = "text-blue-600 border border-blue-300 bg-blue-50 hover:bg-blue-100 hover:text-blue-700";
    const nonActiveClasses = "text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700";

    // Remove active styling from all buttons, then apply to the current button
    $("[id^='pg-']").removeClass(activeClasses).addClass(nonActiveClasses);
    $(`#pg-${currentPage}-btn`).removeClass(nonActiveClasses).addClass(activeClasses);
});
