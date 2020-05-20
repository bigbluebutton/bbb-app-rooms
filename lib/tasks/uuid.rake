desc 'Generate a cryptographically unique uuid (this is typically used to identify the app instance through product_instance_guid)'
task :uuid do
  puts SecureRandom.uuid
end
