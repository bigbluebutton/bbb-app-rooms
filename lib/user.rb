# frozen_string_literal: true

module BbbAppRooms
  class User
    attr_accessor :uid, :full_name, :first_name, :last_name, :email, :roles, :launch_nonce

    def initialize(params)
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def moderator?(moderator_roles)
      moderator_roles = moderator_roles.split(',') unless moderator_roles.is_a?(Array)
      moderator_roles.any? do |role|
        role?(role)
      end
    end

    def admin?
      role?('Admin')
    end

    def role?(role)
      launch_roles.any? do |launch_role|
        launch_role.match(/#{role}/i)
      end
    end

    def username(default)
      return full_name if full_name
      return "#{first_name} #{last_name}" if first_name || last_name
      return email.split('@').first if email

      default
    end

    private

    def launch_roles
      return [] unless roles

      roles.split(',')
    end
  end
end
