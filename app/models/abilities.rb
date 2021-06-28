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
      # `resource` is a `Room`
      # by default every signed in user can download, unless explicitly set not to
      config = ConsumerConfig.select(:download_presentation_video).
                 find_by(key: resource&.consumer_key)
      if resource.present? && config.present? && !config.download_presentation_video?
        user.present? && self.full_permission?(user)
      else
        user.present?
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
end