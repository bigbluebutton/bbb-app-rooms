//= require flatpickr/dist/flatpickr
//= require clipboard

$(document).on('turbolinks:load', function(){
  $('.toast').toast();
  $(".toast.toast-auto").each(function() {
    $(this).toast('show');
  });

  $(".datepicker").each(function() {
    var format = $(this).data('format');
    $(this).flatpickr({
      disableMobile: true,
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

  $(".copy-to-clipboard").each(function() {
    $toast = $('.toast', $(this).data('toast-id'));
    clipboard = new ClipboardJS(this);
    clipboard.on('success', function(e) {
      $toast.toast('dispose');
      $toast.toast('show');
    });
  });

  $(".btn-retry").on('click', function() {
    window.open($(this).data('launch'));
    $(this).addClass('disabled');
    $(this).attr('disabled', '1');
    $(this).removeData('launch');
    return true;
  });
});
