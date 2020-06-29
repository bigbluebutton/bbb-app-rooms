class AppLaunch < ApplicationRecord

  before_save :set_room_handler

  def room_params
    name = self.params['resource_link_title']
    description = self.params['resource_link_description']
    record = has_custom?('record')
    wait_moderator = has_custom?('wait_moderator')
    all_moderators = has_custom?('all_moderators')

    {
      handler: resource_handler,
      name: name,
      description: description,
      welcome: '',
      recording: record,
      wait_moderator: wait_moderator,
      all_moderators: all_moderators
    }
  end

  def user_params
    {
      uid: self.params['user_id'],
      full_name: self.params['lis_person_name_full'],
      first_name: self.params['lis_person_name_given'],
      last_name: self.params['lis_person_name_family'],
      email: self.params['lis_person_contact_email_primary'],
      roles: self.params['roles'],
      locale: self.params['launch_presentation_locale'],
      launch_nonce: self.nonce,
    }
  end

  def has_custom?(type)
    self.params.key?('custom_params') &&
      self.params['custom_params'].key?('custom_' + type) &&
      self.params['custom_params']['custom_' + type] == 'true'
  end

  def resource_handler
    Digest::SHA1.hexdigest(
      'rooms' + self.consumer_id + self.resource_id
    ).to_s
  end

  # The LTI attribute that defines which resource it is
  def resource_id
    self.params['resource_link_id']
  end

  # The LTI attribute that defines who the consumer is
  def consumer_id
    id = self.params['tool_consumer_instance_guid']
    id || self.consumer_domain
  end

  def consumer_domain
    begin
      URI.parse(params['lis_outcome_service_url']).host
    rescue URI::InvalidURIError
      nil
    end
  end

  private

  def set_room_handler
    self.room_handler ||= self.resource_handler
  end
end
