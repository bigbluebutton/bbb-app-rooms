class Abilities

  # This is a simplified authorization mechanism that has three actions:
  # :show, :edit and :admin
  # TODO: verifiy the resource as well
  def self.can?(user, action, resource)
    case action
    when :show
      true
    when :edit
      user.present? && self.full_permission?(user)
    when :admin
      user.present? && user.admin?
    when :download_presentation_video
      config = self.find_consumer_config(resource[:consumer_key],
                                          :download_presentation_video)
      if config[:download_presentation_video]
        user.present?
      else
        user.present? && self.full_permission?(user)
      end
    when :message_reference_terms_use
      config = self.find_consumer_config(resource[:consumer_key],
                                          :message_reference_terms_use)
      if config[:message_reference_terms_use]
        return true
      end
    else
      false
    end
  end

  def self.full_permission?(user)
    user.admin? || user.moderator?(self.moderator_roles)
  end

  def self.moderator_roles
    Rails.configuration.bigbluebutton_moderator_roles.split(',')
  end

  def self.find_consumer_config(key, kind)
    config = ConsumerConfig.select(kind).find_by(key: key)
  end
end
