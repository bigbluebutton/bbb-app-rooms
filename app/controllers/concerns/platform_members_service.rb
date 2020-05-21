# frozen_string_literal: true

module PlatformMembersService
  include ActiveSupport::Concern

  # check if platforms offers names and roles
  def platform_has_nrps?(jwt_body)
    jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice'].present? && jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url'].present?
  end

  # get list of members enrolled in the course this room is in
  def platform_members(registration, jwt_body)
    next_page = jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url']
    external_members = []
    token = access_token(registration, ['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'])

    while next_page.present?

      response = make_service_request(
        registration,
        ['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'],
        'GET',
        next_page,
        nil,
        nil,
        'application/vnd.ims.lti-nrps.v2.membershipcontainer+json',
        token
      )

      if external_members.empty?
        external_members = JSON.parse(response.body)['members']
      else
        external_members += JSON.parse(response.body)['members']
      end

      next_page = false
      response.each_header do |key, value|
        if key.capitalize.match(/Link/) && value.match(/rel=next/)
          next_page = value
        end
      end
    end
    external_members
  end
end
