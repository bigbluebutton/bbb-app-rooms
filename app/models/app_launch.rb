class AppLaunch < ApplicationRecord
  before_save :set_room_handler

  def room_params
    name = self.params['context_title']

    p = {
      handler: resource_handler,
      name: name,
      welcome: '',
      consumer_key: self.consumer_key
    }

    new_room = Room.new
    [
      :recording, :wait_moderator, :all_moderators,
      :allow_wait_moderator, :allow_all_moderators
    ].each do |attr|
      p[attr] = if has_custom_param?(attr.to_s)
                  is_custom_param_true?(attr.to_s)
                else
                  new_room.send(attr)
                end
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

  def custom_param(name)
    params['custom_params']&.[]('custom_' + name)
  end

  def is_custom_param_true?(name)
    params['custom_params']&.[]('custom_' + name) == 'true'
  end

  # Note: this is how a handler of a room is defined after launch, changing this
  # might change the rooms that are associated with a given course/lms/launch.
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
    id = self.oauth_consumer_key

    if id.blank?
      Rails.logger.warn "Empty oauth_consumer_key when calculating the handler on " \
                        "consumer_id=#{self.consumer_id}, context_id=#{self.context_id} " \
                        "oauth_consumer_key=#{self.oauth_consumer_key}"
      id = self.params['tool_consumer_instance_guid']
    end

    if id.blank?
      Rails.logger.warn "Empty tool_consumer_instance_guid when calculating the handler on " \
                        "consumer_id=#{self.consumer_id}, context_id=#{self.context_id} " \
                        "oauth_consumer_key=#{self.oauth_consumer_key}"
      id = self.consumer_domain
    end

    id
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

  def consumer_key
    self.oauth_consumer_key
  end

  def bigbluebutton_server
    ConsumerConfig.find_by_key(consumer_key)&.server
  end

  def brightspace_oauth
    ConsumerConfig.find_by_key(consumer_key)&.brightspace_oauth
  end

  # FIX ME
  # Move to a worker in the future
  def self.remove_old_app_launches
    date_limit = Rails.configuration.launch_days_to_delete.days.ago
    limit_for_delete = Rails.configuration.launch_limit_for_delete
    query_started = Time.now.utc
    get_delete_launches = <<-SQL
        DELETE FROM app_launches WHERE id IN(
        SELECT app_launches.id
        FROM app_launches
        LEFT JOIN scheduled_meetings
        ON nonce = scheduled_meetings.created_by_launch_nonce
        WHERE scheduled_meetings.created_by_launch_nonce IS NULL
        AND expires_at < '#{date_limit}'
        LIMIT '#{limit_for_delete}'
      )
    SQL
    deleted_launches = connection.execute(get_delete_launches).cmd_tuples
    query_duration = Time.now.utc - query_started
    Rails.logger.info "Removing the old AppLaunches from before #{date_limit}, " \
                      "#{deleted_launches} AppLaunches deleted, " \
                      "in: #{query_duration.round(3)} seconds"
  end

  private

  def set_room_handler
    self.room_handler ||= self.resource_handler
  end
end
