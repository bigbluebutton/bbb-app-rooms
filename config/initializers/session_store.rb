# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

attrs = {
  key: '_bbb_app_rooms_session',
  secure: ENV['COOKIES_SECURE_OFF'].blank?,
  same_site: ENV['COOKIES_SAME_SITE'].blank? ? 'None' : ENV['COOKIES_SAME_SITE']
}
Rails.application.config.session_store(:cookie_store, **attrs)
