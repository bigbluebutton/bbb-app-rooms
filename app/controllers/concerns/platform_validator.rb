# frozen_string_literal: true

module PlatformValidator
  include ActiveSupport::Concern

  # LTI 1.0/1.1
  def lti_secret(key, _options = {})
    tool = RailsLti2Provider::Tool.find_by_uuid(key)
    return tool.shared_secret if tool
  end

  # LTI 1.3
  def lti_registration_exists?(iss, options = {})
    RailsLti2Provider::Tool.find_by_issuer(iss, options).present?
  end

  def lti_registration_params(iss, options = {})
    reg = lti_registration(iss, options)
    JSON.parse(reg.tool_settings)
  end

  def lti_registration(iss, options = {})
    RailsLti2Provider::Tool.find_by_issuer(iss, options)
  end
end
