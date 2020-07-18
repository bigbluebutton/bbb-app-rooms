class AppLaunch < ApplicationRecord

  before_save :set_room_handler

  def room_params
    name = self.params['context_title']

    p = {
      handler: resource_handler,
      name: name,
      welcome: ''
    }

    new_room = Room.new
    p[:recording] = if has_custom_param?('record')
                      custom_param_value('record')
                    else
                      new_room.recording
                    end
    p[:wait_moderator] = if has_custom_param?('wait_moderator')
                           custom_param_value('wait_moderator')
                         else
                           new_room.wait_moderator
                         end
    p[:all_moderators] = if has_custom_param?('all_moderators')
                           custom_param_value('all_moderators')
                         else
                           new_room.all_moderators
                         end

    p
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

  def has_custom_param?(name)
    self.params.key?('custom_params') &&
      self.params['custom_params'].key?('custom_' + name)
  end

  def custom_param_value(name)
    self.has_custom_param?(name) &&
      self.params['custom_params']['custom_' + name] == 'true'
  end

  def resource_handler
    handler = Digest::SHA1.hexdigest(
      'rooms' + self.consumer_id + self.context_id
    ).to_s
    Rails.logger.info "Resource handler=#{handler} calculated based on " \
                      "consumer_id=#{self.consumer_id}, context_id=#{self.context_id} " \
                      "oauth_consumer_key=#{self.oauth_consumer_key}"
    handler
  end

  # The LTI attribute that defines which resource it is
  def context_id
    self.params['context_id']
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

  def oauth_consumer_key
    self.params['custom_params']['oauth_consumer_key'] if self.params.key?('custom_params')
  end

  private

  def set_room_handler
    self.room_handler ||= self.resource_handler
  end
end
