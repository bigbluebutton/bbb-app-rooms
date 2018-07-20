module LtiHelper
  def username(default)
    if @launch_params['lis_person_name_full']
      return @launch_params['lis_person_name_full']
    end
    if launch_params['lis_person_name_given'] || launch_params['lis_person_name_family']
      return "#{launch_params['lis_person_name_given']} #{launch_params['lis_person_name_family']}"
    end
    if launch_params['lis_person_contact_email_primary']
      return launch_params['lis_person_contact_email_primary'].split("@").first
    end
    default
  end

  def moderator?
    bigbluebutton_moderator_roles.each do |role|
      return true if role?(role)
    end
    false
  end

  def admin?
    role?("Administrator")
  end

  def role?(role)
    launch_roles.each do |launch_role|
      return true if launch_role.match(/#{role}/i)
    end
    false
  end

  def launch_roles
    return [] unless @launch_params
    return [] unless @launch_params.key?("roles")
    @launch_params["roles"].split(",")
  end
end
