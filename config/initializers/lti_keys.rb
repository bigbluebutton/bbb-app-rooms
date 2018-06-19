require 'helpers'
include LtiToolProvider::Helpers

#blti_keys = LtiToolProvider::Helpers.string_to_hash(ENV["LTI_KEYS"] || 'key:secret')
#
#
#RailsLti2Provider::Tool.delete_all unless blti_keys
#blti_keys.each do |key, secret|
#  tool = RailsLti2Provider::Tool.find_or_initialize_by(uuid: key, lti_version: 'LTI-1p0', tool_settings:'none')
#  tool.update_attributes!(shared_secret: secret)
#end
