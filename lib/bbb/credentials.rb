# frozen_string_literal: true

#  BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
#  Copyright (c) 2020 BigBlueButton Inc. and by respective authors (see below).
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
  class Credentials
    attr_writer :cache, :cache_enabled, :multitenant_api_endpoint, :multitenant_api_secret # Rails.cache store is assumed.  # Enabled by default.

    def initialize(endpoint, secret)
      # Set default credentials.
      @endpoint = endpoint
      @secret = secret
      @multitenant_api_endpoint = nil
      @multitenant_api_secret = nil
      @cache_enabled = true
    end

    def endpoint(tenant)
      return fix_bbb_endpoint_format(@endpoint) if tenant.blank?

      fix_bbb_endpoint_format(tenant_endpoint(tenant))
    end

    def secret(tenant)
      return @secret if tenant.blank?

      tenant_secret(tenant)
    end

    private

    def tenant_endpoint(tenant)
      tenant_info(tenant, 'apiURL')
    end

    def tenant_secret(tenant)
      tenant_info(tenant, 'secret')
    end

    def tenant_info(tenant, key)
      info = fetch_tenant_info(tenant)
      return if info.nil?

      info[key]
    end

    def fetch_tenant_info(tenant)
      raise 'Multitenant API not defined' if @multitenant_api_endpoint.nil? || @multitenant_api_secret.nil?

      # Check up cached info.
      if @cache_enabled
        cached_tenant = @cache.fetch("#{tenant}/api")
        return cached_tenant unless cached_tenant.nil?
      end

      # Build the URI.
      uri = encoded_url(
        "#{@multitenant_api_endpoint}api/getUser",
        @multitenant_api_secret,
        { name: tenant }
      )

      http_response = http_request(uri)
      response = parse_response(http_response)

      # Return the user credentials if the request succeeded on the External Tenant Manager.
      @cache.fetch("#{tenant}/api", expires_in: 1.hour) do
        response
      end
    end

    def http_request(uri)
      # Make the request.
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      response = http.get(uri.request_uri)
      raise 'Error on response' unless response.is_a?(Net::HTTPSuccess)

      response
    end

    def parse_response(response)
      # Parse XML.
      doc = XmlSimple.xml_in(response.body, 'ForceArray' => false)

      raise doc['message'] unless response.is_a?(Net::HTTPSuccess)

      # Return the user credentials if the request succeeded on the External Tenant Manager.
      return doc['user'] if doc['returncode'] == 'SUCCESS'

      raise "User with tenant #{tenant} does not exist." if doc['messageKey'] == 'noSuchUser'

      raise "API call #{url} failed with #{doc['messageKey']}."
    end

    def encoded_url(endpoint, secret, params)
      encoded_params = params.to_param
      string = "getUser#{encoded_params}#{secret}"
      checksum_algorithm = Rails.configuration.checksum_algorithm
      checksum = OpenSSL::Digest.digest(checksum_algorithm, string).unpack1('H*')
      URI.parse("#{endpoint}?#{encoded_params}&checksum=#{checksum}")
    end

    # Fixes BigBlueButton endpoint ending.
    def fix_bbb_endpoint_format(endpoint)
      # Fix endpoint format only if required.
      endpoint += '/' unless endpoint.ends_with?('/')
      endpoint += 'api/' if endpoint.ends_with?('bigbluebutton/')
      endpoint += 'bigbluebutton/api/' unless endpoint.ends_with?('bigbluebutton/api/')
      endpoint
    end
  end
end
