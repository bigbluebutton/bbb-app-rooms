class Abilities

  # This is a simplified authorization mechanism that has three actions:
  # :show, :edit and :admin
  # TODO: verifiy the resource as well
  def self.can?(user, action, resource)
    case action
    when :show
      true
    when :edit
      user.present? && (user.admin? || user.moderator?(self.moderator_roles))
    when :admin
      user.present? && user.admin?
    else
      false
    end
  end

  def self.moderator_roles
    Rails.configuration.bigbluebutton_moderator_roles.split(',')
  end
end
