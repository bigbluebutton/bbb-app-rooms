# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

attrs = {
  key: '_bbb_app_rooms_session'
}
if ENV['DISABLE_COOKIE_FOR_IFRAME'].blank?
  attrs = attrs.merge(
    {
      same_site: :none,
      secure: true
    }
  )
end
Rails.application.config.session_store(:cookie_store, attrs)
