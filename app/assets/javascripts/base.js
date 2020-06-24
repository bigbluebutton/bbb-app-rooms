$(document).on('turbolinks:load', function(){
  $(".datepicker").flatpickr({
    enableTime: false,
    dateFormat: "Y-m-d",
    minDate: new Date(),
  });

  $(".timepicker").flatpickr({
    enableTime: true,
    noCalendar: true,
    dateFormat: "H:i",
    time_24hr: true,
  });
});
