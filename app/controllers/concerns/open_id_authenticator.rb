# frozen_string_literal: true

module OpenIdAuthenticator
  include ActiveSupport::Concern

  def verify_openid_launch
    validate_openid_message_state

    jwt_parts = validate_jwt_format
    jwt_header = JSON.parse(Base64.urlsafe_decode64(jwt_parts[0]))
    jwt_body = JSON.parse(Base64.urlsafe_decode64(jwt_parts[1]))

    puts jwt_header
    puts jwt_body
    validate_nonce(jwt_body)

    # validate registration (deployment)
    reg = validate_registration(jwt_body)
    validate_jwt_signature(reg, jwt_header)
    validate_openid_message(jwt_body)

    clean_up_openid_launch
    params.merge! extract_old_param_format(jwt_body)

    # token is too big to store in cookie for rooms and we've already decoded it
    params.delete :id_token

    {
      header: jwt_header,
      body: jwt_body
    }
  end

  def validate_openid_message_state
    raise CustomError, :state_not_found unless cookies.key?(params[:state])
    raise CustomError, :missing_id_token unless params.key?('id_token')
  end

  def validate_jwt_format
    jwt_parts = params[:id_token].split('.')
    raise CustomError, :invalid_id_token unless jwt_parts.length == 3

    jwt_parts
  end

  def validate_nonce(jwt_body)
    raise CustomError, :invalid_nonce unless jwt_body['nonce'] == Rails.cache.read('lti1p3_' + jwt_body['nonce'])[:nonce]
  end

  def validate_registration(jwt_body)
    registration = RailsLti2Provider::Tool.find_by_issuer(jwt_body['iss'])
    raise CustomError, :not_registered if registration.nil?

    JSON.parse(registration.tool_settings)
  end

  def validate_jwt_signature(reg, jwt_header)
    public_key_set = JSON.parse(open(reg['key_set_url']).string)
    jwk_json = public_key_set['keys'].find do |key|
      key['kid'] == jwt_header['kid']
    end
    jwt = JSON::JWK.new(jwk_json)

    # throws error if jwt is not valid
    JWT.decode params[:id_token], jwt.to_key, true, algorithm: 'RS256'
  end

  def validate_openid_message(jwt_body)
    raise CustomError, :invalid_message_type if jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'].empty?
  end

  def clean_up_openid_launch
    cookies.delete(params[:state])
  end

  def extract_old_param_format(jwt_body)
    if jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings'].present?
      # get deep link information
      p = old_content_type_format(jwt_body)
    else
      # get old message format
      p = old_message_format(jwt_body)
    end

    p.each do |key, value|
      p[:"#{key}"] = '' if value.nil?
    end
    p
  end

  def extract_old_roles(jwt_body)
    roles = ''
    if jwt_body.key? 'https://purl.imsglobal.org/spec/lti/claim/roles'
      jwt_body['https://purl.imsglobal.org/spec/lti/claim/roles'].each do |r|
        roles + r.split('#', -1)[-1]
        roles + ',' unless r == jwt_body['https://purl.imsglobal.org/spec/lti/claim/roles'].last
      end
    end
    roles
  end

  def old_message_format(jwt_body)
    p = {
      lis_person_name_full: jwt_body['name'],
      lis_person_name_given: jwt_body['given_name'],
      lis_person_lis_person_name_family: jwt_body['family_name'],
      lis_person_contact_email_primary: jwt_body['email'],
      lti_version: jwt_body['https://purl.imsglobal.org/spec/lti/claim/version'],
      roles: extract_old_roles(jwt_body)
    }

    p = extract_param(p, jwt_body, 'https://purl.imsglobal.org/spec/lti/claim/resource_link',
        {
            'resource_link_id': 'id',
            'resource_link_title': 'title',
            'resource_link_description': 'description'
        })

    p = extract_param(p, jwt_body, 'https://purl.imsglobal.org/spec/lti/claim/launch_presentation',
        {
            'launch_presentation_return_url': 'return_url',
            'launch_presentation_locale': 'locale',
            'launch_presentation_document_target': 'document_target'
        })

    p = extract_param(p, jwt_body, 'https://purl.imsglobal.org/spec/lti/claim/tool_platform',
        {
            'tool_consumer_instance_guid': 'guid',
            'tool_consumer_info_product_family_code': 'family_code',
            'tool_consumer_info_version': 'version',
            'tool_consumer_instance_name': 'name',
            'tool_consumer_instance_description': 'description'
        })

    p = extract_param(p, jwt_body, 'https://purl.imsglobal.org/spec/lti/claim/context',
        {
            'context_id': 'id',
            'context_label': 'label',
            'context_title': 'title',
            'user_id': 'id'
        })

    p = extract_param(p, jwt_body, 'https://purl.imsglobal.org/spec/lti-bos/claim/basicoutcomesservice',
        {
            'lis_result_sourcedid': 'lis_result_sourcedid',
            'lis_outcome_service_url': 'lis_outcome_service_url',
        })

    p = extract_param(p, jwt_body, 'https://purl.imsglobal.org/spec/lti/claim/ext',
        {
            'ext_user_username': 'user_username',
            'ext_lms': 'lms',
        })

    p = extract_param(p, jwt_body, 'https://purl.imsglobal.org/spec/lti/claim/lis',
        {
            'lis_person_sourcedid': 'person_sourcedid'
        })

    if jwt_body.key?('https://purl.imsglobal.org/spec/lti/claim/custom')
      jwt_body['https://purl.imsglobal.org/spec/lti/claim/custom'].each do |key, value|
        p[:"custom_#{key}"] = value
      end
    end

    if jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiResourceLinkRequest'
      p[:lti_message_type] = 'basic-lti-launch-request'
    elsif jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiDeepLinkingRequest'
      p[:lti_message_type] = 'ContentItemSelectionRequest'
    end
    p
  end

  def extract_param(p, jwt_body, key, pairs)
    if jwt_body.key? (key)
        pairs.each do |old_param, new_param|
            p[:"#{old_param}"] = jwt_body[key][new_param]
        end
    end
    p
  end

  def old_content_type_format(jwt_body)
    p = {
      resource_link_id: '',
      lis_person_sourcedid: jwt_body['https://purl.imsglobal.org/spec/lti/claim/lis']['person_sourcedid'],
      roles: extract_old_roles(jwt_body),
      context_id: jwt_body['https://purl.imsglobal.org/spec/lti/claim/context']['id'],
      context_label: jwt_body['https://purl.imsglobal.org/spec/lti/claim/context']['label'],
      context_title: jwt_body['https://purl.imsglobal.org/spec/lti/claim/context']['title'],
      context_type: jwt_body['https://purl.imsglobal.org/spec/lti/claim/context']['type'].join(','),
      lis_course_section_sourcedid: jwt_body['https://purl.imsglobal.org/spec/lti/claim/lis']['course_section_sourcedid'],
      launch_presentation_locale: jwt_body['https://purl.imsglobal.org/spec/lti/claim/launch_presentation']['locale'],
      ext_lms: jwt_body['https://purl.imsglobal.org/spec/lti/claim/ext']['lms'],
      tool_consumer_info_product_family_code: jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['family_code'],
      tool_consumer_info_version: jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['version'],
      lti_version: jwt_body['https://purl.imsglobal.org/spec/lti/claim/version'],
      tool_consumer_instance_name: jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['name'],
      tool_consumer_instance_description: jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['description'],
      accept_media_types: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['accept_types'].join(','),
      accept_presentation_document_targets: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['accept_presentation_document_targets'].join(','),
      accept_copy_advice: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['accept_copy_advice'],
      accept_multiple: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['accept_multiple'],
      accept_unsigned: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['accept_unsigned'],
      auto_create: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['auto_create'],
      can_confirm: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['can_confirm'],
      content_item_return_url: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['deep_link_return_url'],
      title: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['title'],
      text: jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['text']
    }
    p[:lti_message_type] = 'basic-lti-launch-request' if jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiResourceLinkRequest'
    p[:lti_message_type] = 'ContentItemSelectionRequest' if jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiDeepLinkingRequest'
  end
end
