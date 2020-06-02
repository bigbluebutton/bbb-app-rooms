class User < ApplicationRecord
  def admin?
    self.roles.include?("Administrator") || self.roles.include?("Admin")
  end

  def moderator?(roles)
    roles.each { |role|
      return true if self.roles.include?(role)
    }
  end

  def username(default)
    if self.full_name
      return self.full_name
    end
    if self.first_name || self.last_name
      return "#{self.last_name}, #{self.first_name}"
    end
    if self.email
      return self.email.split("@").first
    end
    default
  end

end
