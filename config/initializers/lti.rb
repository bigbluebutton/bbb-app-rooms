LTI_CONFIG = YAML.load(File.read("#{Rails.root}/config/lti.yml"))[Rails.env] || {}

LTI_CONFIG[:tools].to_h.each do |key, props|
    props["uid"] = ENV['APP_ROOMS_UID'] if ENV['APP_ROOMS_UID']
    props["secret"] = ENV['APP_ROOMS_SECRET'] if ENV['APP_ROOMS_SECRET']
    props["site"] = ENV['APP_ROOMS_SITE'] if ENV['APP_ROOMS_SITE']
end

LTI_CONFIG.symbolize_keys!
