class User
  attr_accessor :uid, :roles, :full_name, :first_name, :last_name, :email

  def initialize(params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def moderator?(moderator_roles)
    moderator_roles.each do |role|
      return true if role?(role)
    end
    false
  end

  def admin?
    role?('Administrator')
  end

  def role?(role)
    launch_roles.each do |launch_role|
      return true if launch_role.match(/#{role}/i)
    end
    false
  end

  def username(default)
    if self.full_name
      return self.full_name
    end
    if self.first_name or self.last_name
      return "#{self.first_name} #{self.last_name}"
    end
    if self.email
      return self.email.split("@").first
    end
    default
  end

  private

    def launch_roles
      return [] unless self.roles
      self.roles.split(",")
    end

end
