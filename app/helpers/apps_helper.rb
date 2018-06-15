module AppsHelper
  def lti_application_allowed
    raise "app not specified" unless params.has_key?(:app)
    raise "app not allowed" unless params[:app] == 'default' || lti_apps.key?(params[:app])
  end

  def lti_apps
    str =  ENV["LTI_APPS"] || ''
    logger.info str
    Hash[
      str.split(',').map do |pair|
        logger.info pair
        k, v = pair.split(':', 2)
        [k, v]
      end
    ]
  end
end
