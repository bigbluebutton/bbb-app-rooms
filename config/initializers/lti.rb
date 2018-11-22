LTI_CONFIG = YAML.load(File.read("#{Rails.root}/config/tool_providers.yml"))[Rails.env] || {}
LTI_CONFIG.symbolize_keys!
