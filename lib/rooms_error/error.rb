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

module RoomsError
  class CustomError < StandardError
    attr_accessor :code, :key, :message, :suggestion, :status

    def initialize(options = {})
      super(options[:message])
      self.code = options[:code] || 500
      self.key = options[:key] || :internal_error
      self.message = options[:message] || 'Something went wrong'
      self.suggestion = options[:suggestion]
      self.status = options[:status] || @code
    end

    def fetch_json
      { code: code,
        key: key,
        message: message,
        suggestion: suggestion,
        status: status, }
    end
  end
end
