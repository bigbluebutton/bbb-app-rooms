# frozen_string_literal: true

#  BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
#  Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
#  This program is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free Software
#  Foundation; either version 3.0 of the License, or (at your option) any later
#  version.
#
#  BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License along
#  with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'net/http'
require 'xmlsimple'

module Bbb
  module Api
    # Rereives info from External Tenant Manager in regards to the tenant.
    def retrieve_tenant_info(tenant)
        # Check up cached info.
        if Rails.configuration.cache_enabled
          cached_tenant = Rails.cache.fetch("#{tenant}/api")
          return cached_tenant unless cached_tenant.nil?
        end

        # Build the URI.
        uri = encode_url(
          Rails.configuration.external_multitenant_endpoint + 'api/getUser',
            Rails.configuration.external_multitenant_secret,
            { name: tenant }
        )
        logger.info uri

        # Make the request.
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        response = http.get(uri.request_uri)

        raise 'Error on response' unless response.is_a?(Net::HTTPSuccess)

        # Parse XML.
        doc = XmlSimple.xml_in(response.body, 'ForceArray' => false)

        raise doc['message'] unless response.is_a?(Net::HTTPSuccess)

        # Return the user credentials if the request succeeded on the External Tenant Manager.
        Rails.cache.fetch("#{tenant}/api", expires_in: 1.hours) do
            doc['user']
        end

        # Return the user credentials if the request succeeded on the External Tenant Manager.
        return doc['user'] if doc['returncode'] == 'SUCCESS'

        raise "User with tenant #{tenant} does not exist." if doc['messageKey'] == 'noSuchUser'
        raise "API call #{url} failed with #{doc['messageKey']}."
    end

    def encode_url(endpoint, secret, params)
        encoded_params = params.to_param
        string = 'getUser' + encoded_params + secret
        checksum = OpenSSL::Digest.digest('sha1', string).unpack1('H*')
        URI.parse("#{endpoint}?#{encoded_params}&checksum=#{checksum}")
    end

    def bbb_credentials
      # Return default credentials if no tenant has been set.
      return {
          endpoint: Rails.configuration.bigbluebutton_endpoint,
          secret: Rails.configuration.bigbluebutton_secret,
        } if @room.tenant.nil? || @room.tenant.empty?
      # Return credentials retrieved from External Tenant Manager.
      tenant_info = retrieve_tenant_info(@room.tenant)
      return {
          endpoint: tenant_info['apiURL'],
          secret: tenant_info['secret'],
        } unless tenant_info.nil?
    end

    private

    # Sets a BigBlueButtonApi object for interacting with the API.
    def bbb
      @bbb = BigBlueButton::BigBlueButtonApi.new(remove_slash(fix_bbb_endpoint_format(bbb_credentials[:endpoint])), bbb_credentials[:secret], '0.9', 'true')
    end

    # Fixes BigBlueButton endpoint ending.
    def fix_bbb_endpoint_format(url)
      # Fix endpoint format only if required.
      url += '/' unless url.ends_with?('/')
      url += 'api/' if url.ends_with?('bigbluebutton/')
      url += 'bigbluebutton/api/' unless url.ends_with?('bigbluebutton/api/')
      url
    end

    # Removes trailing forward slash from a URL.
    def remove_slash(str)
      str.nil? ? nil : str.chomp('/')
    end
  end
end
