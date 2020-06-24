$(document).on('turbolinks:load', function(){
  $(".datepicker").each(function() {
    var format = $(this).data('format');
    $(this).flatpickr({
      enableTime: false,
      dateFormat: format,
      minDate: new Date(),
    });
  });

  $(".timepicker").each(function() {
    var format = $(this).data('format');
    $(this).flatpickr({
      enableTime: true,
      noCalendar: true,
      dateFormat: format,
      time_24hr: true,
    });
  });
});
