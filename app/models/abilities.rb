class Abilities
  def self.can_edit?(user, resource)
    # TODO: verifiy the resource as well
    user.admin? || user.moderator?(self.moderator_roles)
  end

  def self.moderator_roles
    Rails.configuration.bigbluebutton_moderator_roles.split(',')
  end
end
