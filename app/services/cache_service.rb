# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

class CacheService
  def self.fetch_or_compute(cache_key, expiration = Rails.configuration.cache_expires_in_minutes.minutes, &block)
    if Rails.configuration.cache_enabled
      Rails.logger.debug("[CacheService] Cache enabled, attempt to fetch cache for the following key: #{cache_key}")
      Rails.cache.fetch(cache_key, expires_in: expiration, &block)
    else
      yield
    end
  end

  def self.delete(cache_key)
    Rails.cache.delete(cache_key) if Rails.configuration.cache_enabled
  end
end
