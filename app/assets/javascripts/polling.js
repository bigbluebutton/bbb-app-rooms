// Javascript logic to set, pause and resume a polling.
// Uses setTimeout() recursively instead of setInterval() to have a better control of pauses.
// 'callback' is the function we want to call every timer cycle and 'delay' is the length of the cycle.
// The delay is set with the meta tag 'polling-delay' of the base layout. The tag's value comes from
// an environment variable. If there is no environment variable for the delay, the default value is set to 10 seconds.

class Polling {
  static setPolling(callback) {
    var delay, pause, remaining, resume, start, timerId;
    delay = $('meta[name="running-polling-delay"]').attr("content") || 10000;
    remaining = 0; // The first callback is instantaneous

    var pause = function() {
      clearTimeout(timerId);
      remaining -= new Date() - start;
    };

    var resume = function() {
      start = new Date();
      // Sets the next cycle with the remaining time, 
      // calls resume() recursively with the full cycle length and
      // calls the callback().
      timerId = setTimeout((function() {
        remaining = delay;
        resume();
        callback();
      }), remaining);
    };

    $(document).ready(function() {
      resume()
    })

    $(document).on("visibilitychange", function() {
      var timeAway;
      if (document.visibilityState === 'visible') {
        // If the user stays more than 1 timer cycle away from the page, 
        // it will resume instantly when he comes back.
        timeAway = new Date() - start;
        if (timeAway > delay) {
          remaining = 0;
        }
        resume();
      } else {
        pause();
      }
    });
  }
}
