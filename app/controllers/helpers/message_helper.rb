module MessageHelper
  def resource_handler(tc_instance_guid, params)
    Digest::SHA1.hexdigest(params[:app] + tc_instance_guid + params["resource_link_id"])
  end

  def user_params(tc_instance_guid, params)
    {
      context: tc_instance_guid,
      uid: params['user_id'],
      full_name: params['custom_lis_person_name_full'] || params['lis_person_name_full'],
      first_name: params['custom_lis_person_name_given'] || params['lis_person_name_given'],
      last_name: params['custom_lis_person_name_family'] || params['lis_person_name_family'],
      last_accessed_at: DateTime.now,
    }
  end

  def tool_consumer_instance_guid(request_referrer, params)
    params['tool_consumer_instance_guid'] || URI.parse(request_referrer).host
  end

  def authorized_tools
    tools = Doorkeeper::Application.all.select("id, name, uid, secret, redirect_uri").to_a.map { |app| [app.name, app.attributes] }.to_h
    tools['default'] = {}
    tools
  end

  def lti_secret(key)
    tool = RailsLti2Provider::Tool.find_by_uuid(key)
    return tool.shared_secret if tool
  end
end
  