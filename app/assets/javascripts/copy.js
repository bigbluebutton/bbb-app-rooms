$(document).on('turbolinks:load', function(){

    $('.click-to-copy').on('click', function() {
        let self = $(this);
        self.select();
        // $(this).setSelectionRange(0, 99999); /* For mobile devices */

        copied_txt = 'Copied!';

        document.execCommand("copy");
        self
            .data('placement', 'top')
            .attr('title', copied_txt)
            .tooltip('show');

        setTimeout(function() {
            self.tooltip('destroy');
        }, 2000);
    });

});