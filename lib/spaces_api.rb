require 'aws-sdk-s3'

# Spaces is an S3-compatible DigitalOcean object storage service. The API is inter-operable with
# the AWS S3 API, so we can use the 'aws-sdk-s3' gem to access it.
# DigitalOcean guide: https://www.digitalocean.com/docs/spaces/resources/s3-sdk-examples/
# S3 API documentation: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client
module SpacesApi
  # Returns an array of periods present in the bucket, e.g. ['2020-11', '2020-10']
  def get_room_reports(room)
    prefix = default_prefix(room)
    # Array of full reports keys, e.g. ['lti/pearson-coc/room_handler/2020-11/report-en.csv', ...]
    reports_keys = client.list_objects_v2({
      bucket: default_bucket,
      prefix: prefix
    }).contents.map(&:key)
    reports = []
    reports_keys.each do |key|
      # Gets only the period from the full report key
      split_key = key.split('/')
      reports.push(split_key[3]) unless reports.include?(split_key[3])
    end

    reports.reverse
  end

  # Generates a presigned url with 5 minutes expiration to download a report file
  def report_download_url(room, period, file_format)
    key = default_prefix(room) + period + "/report-#{I18n.locale}." + file_format
    signer = Aws::S3::Presigner.new(client: client)
    url = signer.presigned_url(
      :get_object,
      bucket: default_bucket,
      key: key,
      expires_in: 300
    )

    url
  end

  private
  
  def client
    client = Aws::S3::Client.new(
      access_key_id: Rails.configuration.spaces_key,
      secret_access_key: Rails.configuration.spaces_secret,
      endpoint: Rails.configuration.spaces_endpoint,
      region: 'us-east-1'
    )

    client
  end

  def default_bucket
    Rails.configuration.spaces_bucket
  end

  def default_prefix(room)
    Rails.configuration.spaces_common_prefix + "#{room.consumer_key}/#{room.handler}/"
  end
end