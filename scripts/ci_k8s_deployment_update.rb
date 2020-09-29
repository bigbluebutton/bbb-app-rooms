# frozen_string_literal: true

require 'json'

k8s_image = ARGV[0]
k8s_filename = ARGV[1]

# get json string
s = File.read(k8s_filename)

# parse and convert JSON to Ruby
obj = JSON.parse(s)

# update container image
obj['spec']['template']['spec']['containers'].first['image'] = k8s_image
# update container DEPLOYMENT_TIMESTAMP env
obj['spec']['template']['spec']['containers'].first['env'].each do |kv|
  kv['value'] = "\"#{Time.now.to_i}\"" if kv['name'] == 'DEPLOYMENT_TIMESTAMP'
end

# put json string
File.write(k8s_filename, JSON.pretty_generate(obj))
