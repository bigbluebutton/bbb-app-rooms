# Change Log

## 0.4.2 Elos - 2021-01-17

* Fix typo on `AppLaunch#custom_param_true?`, now called `AppLaunch#is_custom_param_true?`.


## 0.4.1 Elos - 2021-01-17

* [LTI-4] When a user tries to edit an event that has no entry in Brightspace's calendar yet, it
  will now create the event in the calendar instead of showing an error.


## 0.4.0 Elos - 2020-12-16

* [ELOSP-578] Include a link to the LTI meeting in the event created in Brigthspace's calendar.
  The link opens a new tab, launches the LTI and directs the user to the meeting's page (for now
  this is the external page, since there's no meetings#show).
* [ELOSP-607] Fix an error that would occur related to the integration with Brigthspace's calendar.
  It happened after a launch with an expired AppLaunch was made and resulted in an ugly error page
  for users. It now shows the proper error page as it did before.
* [ELOSP-577] Fix editing a meeting to be non recurring after it was created being a recurring
  meeting (it was not possible, it would be recurring forever).


## 0.3.1 Elos - 2020-11-16

* [PR#10] Small fixes to try to remove an error in the authentication for some users. The first
  lines of the error look like:
    ```
    \nNoMethodError (undefined method `[]' for nil:NilClass):\n  \nrack (2.2.3) lib/rack/etag.rb:38:in `call'\nrack (2.2.3) lib/rack/conditional_get.rb:27:in `call' \nrack (2.2.3) lib/rack/head.rb:12:in `call'\nactionpack (6.0.3.1)
    ```


## 0.3.0 Elos - 2020-11-15

* [ELOSP-585] Add a new page to list the reports for an LTI room. Reports are stored in
  DigitalOcean's Spaces and might or might not exist for a room. It builds the list dynamically
  and allows the user to download directly from Spaces using authenticated temporary URLs.
* [ELOSP-602] Fix an error when the app couldn't find an AppLaunch when trying to authenticate
  on a Brightspace LMS as part of the integration with their calendar.


## 0.2.0 Elos - 2020-11-07

* [ELOSP-455] Integration with Brightspace's calendar. Includes a refactor of the configurations
  in the database. Use the rake task `db:brightspace:add` to configure a Brightspace for a consumer
  key and enable the integration with its calendar.
* [ELOSP-574] Edit and remove events in Brightspace's calendar when they are edited or removed
  in the application.


## 0.1.3 Elos - 2020-09-24

* [ELOSP-454] New hints for the new configuration options added in 0.1.3.
* Change the text in the "try again" button to "join", "try again" gives a false impression
  that an error happened.


## 0.1.2 Elos - 2020-09-13

* [ELOSP-454] New configuration options in conferences (by default they are all false, so
  that the features are enabled):
  * Disable the external link;
  * Disable private chat;
  * Disable shared notes.


## 0.1.1 Elos - 2020-08-29

* Better rescue for BigBlueButton exceptions so they won't throw a 500 error, instead they will
  show a toast with the error for the user. Also log all 500 errors so we can track them.
* Auto join the user after a few seconds if a `meetingAlreadyBeingCreated` error happens.
* Create the meeting only if it's not already running. Would create the meeting always when a user
  with permission to create would try to join.
* [ELOSP-498] Fix toasts not being closable.
* Notify connected users that a meeting was created only if cable is enabled.


## 0.1.0 Elos - 2020-08-16

* [ELOSP-457] Use `oauth_consumer_key` when generating room handlers. This key is set by the broker
  in the launch, so it's more secured, can't be edited by the LMS. This makes it more certain
  that handlers will be unique for each key used, so different clients won't mess with
  others' rooms.
* Add favicons to `public/rooms/`, so they don't use the fingerprints when served. The links in
  the XML the broker serves use this URL.
* Auto join the user if going to /wait and the meeting is running.
* Set `cache-control` for all assets when serving assets in production.
* Paginate the list of scheduled meetings with kaminari.
* Use the browser's timezone over the default timezone. After a request, a js sets the timezone in
  a cookie so the server can use it. In the first request it won't be there, so it will use the
  default timezone set in the env variable.
* Add env variable `FORCE_DEFAULT_TIMEZONE` to force the default timezone and ignore the one
  in the cookie. Brings back the old behaviour.
* Show the user the time zone being used in the dates right below the tables and in the tooltip
  of the form components that have a date/time.
* Better errors in general, mostly when URLs are not found (weird links). Less false 500 errors.


## 0.0.16 Elos - 2020-08-02

* Add recurring events with the options: weekly and biweekly. The event is reused, it just
  updates its date on rooms/show if it already expired.


## 0.0.15 Elos - 2020-07-22

* Add option to copy the playback link in a recording.
* Add a table `consumer_configs` to store configurations for each customer. Indexed by the key
  the consumer uses to launch the LTI.
* Add a disclaimer in the external access page. Configure for each customer, by default won't
  show anything.
* Set the duration on create. By default won't set the duration, only when the consumer is configured
  to do so. Sets the duration to the duration of the scheduled meeting plus one hour.
* Serve an html in `/healthz.html` to try to speed up the application boot. Kubernetes will check
  it right after the pod starts and it will take a while to respond while Rails loads, so this
  loading time won't affect user requests.
* Add `Room#consumer_key` to optimize db queries. Uses it directly instead of having to list
  all app launches to get the latest one.
* Set `key` as unique in the `bigbluebutton_servers` and `consumer_configs` tables.
* Show meetings for one hour more than their duration to make it a little better for people in
  other timezones until we have a proper solution for multiple timezones.


## 0.0.14 Elos - 2020-07-20

* Fix to use the locale in the launch over the default locale of the browser.
* Fix validation of the room when accessing open routes for scheduled meetings. Accessing
  `:room/scheduled_meetings/:id/external`, for example, was not validating the room, so any meeting
  could be accessed in the scope of any valid room. Now scheduled meetings are only searched
  in the scope of the current room.


## 0.0.13 Elos - 2020-07-19

* Fix the datetime input in mobile by disabling the native integration. Will show
  the selector just as it does in a desktop browser.
* Configure the session cookie with SameSite=None and Secure. Necessary to open the application
  in an iframe, Chrome started blocking cookies otherwise.
* When creating a meeting, initiate it with attributes from its room, that can be configured
  using custom parameters in the launch.
* Add custom parameters to the launch to enable/disable edition of the flags `all_moderators`
  and `wait_moderator`. The parameters are called `allow_all_moderators` and `allow_wait_moderator`.
  If they are not informed, users are allowed to edit the attributes when editing and creating
  scheduled meetings. If they are informed with `true` (has to be this value), users are also
  allowed to edit the attributes. If they are informed with any other value, users will not
  see the attributes in the views, will not be allowed to edit them and they will assume
  their default values when used (`wait_moderator=true` and `all_moderators=false`).
  * New migration to include the attributes `allow_all_moderators` and `allow_wait_moderator`
    on the table `rooms`.


## 0.0.12 Elos - 2020-07-13
