$(document).on('turbolinks:load', function(){
  var valueSelect = document.getElementsByName("scheduled_meeting[duration]")[0],
    contentCustomDuration = document.getElementById("content_custom_duration")

  valueSelect.addEventListener('change', controlCustomDuration)
  function controlCustomDuration(e) {
    let valueSelectDuration = e.target.value;
    valueSelectDuration == 0 ? contentCustomDuration.classList.add('d-block') :
      contentCustomDuration.classList.remove('d-block')
  }

  if(window.location.href.includes('/edit')){
    var duration = document.getElementsByName("scheduled_meeting[custom_duration]")[0].value,
        durationSeconds = (duration.split(':')[0] * 60 * 60 ) + ( duration.split(':')[1] * 60 ),
        durationsDefault = []
    valuesDefault = document.getElementsByName('scheduled_meeting[duration]')[0].options
    transformTimeToDuration(durationSeconds)
    function transformTimeToDuration(duration) {
      for(var i = 0; i < valuesDefault.length; i++) {
        durationsDefault.push(valuesDefault[i].value)
        if (durationsDefault.includes(duration.toString())){
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
})
