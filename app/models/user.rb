class User < ApplicationRecord
  def admin?
    self.roles.include?("Administrator") || self.roles.include?("Admin")
  end

  def moderator?
    true
  end
end
