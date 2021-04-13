$(document).on('turbolinks:load', function(){
  var valueSelect = document.getElementsByName("scheduled_meeting[duration]")[0],
    contentCustomDuration = document.getElementById("content_custom_duration"),
    fieldHour = document.getElementsByName("scheduled_meeting[custom_duration(4i)]")[0].value
    fieldMinutes = document.getElementsByName("scheduled_meeting[custom_duration(5i)]")[0].value

  valueSelect.addEventListener('change', controlCustomDuration)

  if(window.location.href.includes('/edit')){
    transformTimeToDuration(fieldHour, fieldMinutes)
    function transformTimeToDuration(hour, minutes) {
      duration = (hour * 60 * 60) + (minutes * 60)
      valuesDefault = document.getElementsByName('scheduled_meeting[duration]')[0].options
      for(var i = 0; i < valuesDefault.length; i++) {
        var arrayOptionsDefault = valuesDefault[i].value
        if (arrayOptionsDefault.includes(duration)){
          valueSelect.value = duration
          contentCustomDuration.classList.remove('d-block')
          break
        } else {
          valueSelect.value = 0
          contentCustomDuration.classList.add('d-block')
        }
      }
    }
  }

  function controlCustomDuration(e) {
    let valueSelectDuration = e.target.value;
    valueSelectDuration == 0 ?
      contentCustomDuration.classList.add('d-block') :
      contentCustomDuration.classList.remove('d-block')
  }
})
