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
class Room < ApplicationRecord
  include BrokerHelper

  has_one_attached :presentation

  before_save :default_values

  store_accessor :settings, %i[lockSettingsDisableCam lockSettingsDisableMic lockSettingsDisablePrivateChat lockSettingsDisablePublicChat lockSettingsDisableNote]
  store_accessor :settings, %i[allModerators guestPolicy record autoStartRecording allowStartStopRecording defaultRecordingPublish]

  # after_find is used for the following so that rooms that already exist will have these fields upon launch
  after_find :initialize_setting_defaults, if: :settings_blank?
  before_create :ensure_unique_code

  attr_accessor :can_grade

  validate :shared_code_presence, if: -> { use_shared_code }

  RECORDING_SETTINGS = [:record, :autoStartRecording, :allowStartStopRecording, :defaultRecordingPublish].freeze
  ROOM_SETTINGS = [:guestPolicy, :allModerators].freeze
  CODE_LENGTH = 10

  def default_values
    self.handler ||= Digest::SHA1.hexdigest(SecureRandom.uuid)
    self.moderator = random_password(8) if moderator.blank?
    self.viewer = random_password(8, moderator) if viewer.blank?
  end

  def broadcast_room_start
    ActionCable.server.broadcast("wait_channel:room_#{id}", action: 'started')
  end

  def handler
    return self[:handler_legacy] unless self[:handler_legacy].nil?

    self[:handler]
  end

  def self.recording_setting?(setting)
    RECORDING_SETTINGS.include?(setting.to_sym)
  end

  # Changes the shared code such that the other rooms can't connect to it anymore
  def revoke_shared_code
    # reset the shared code of the children rooms
    reset_children
    # Generate a new code for the room
    ensure_unique_code
    save!
  end

  def reset_children
    children = Room.where(shared_code: code)
    children.each do |child|
      child.update!(shared_code: -1, use_shared_code: false)
      logger.info("[room.rb] Room #{child.id} was using a shared code that was revoked. It's now been reset.")
    rescue StandardError
      logger.error("[room.rb] Error resetting room #{child.id} to original code: #{child.code}")
    end
  end

  # Checks if the room has been reset, and if so, it will reset the room's shared code to the original code
  # and set use_shared_code to false.
  # Returns true if the room was reset, false otherwise.
  def shared_code_revoked?
    if shared_code == -1.to_s
      begin
        update!(shared_code: code)
        return true
      rescue StandardError
        logger.error("[room.rb] Error resetting room #{id}'s shared code to original code: #{code}")
      end
    end
    false
  end

  # Returns many rooms are using this room's code
  def count_by_shared_code
    logger.info("[Room.rb] Calculating count by shared code for Room #{id}")

    return 0 if shared_code.blank?

    children_count = Room.where(shared_code: code).count
    children_count -= 1 if shared_code == code
    children_count
  end

  private

  def random_password(length, reference = '')
    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
    password = ''
    loop do
      password = (0...length).map { o[rand(o.length)] }.join
      break unless password == reference
    end
    password
  end

  # for newly created rooms or previous rooms that don't have settings.
  # will also check if a setting was added to the store_accessor and will go through the initialization if so.
  def settings_blank?
    @stored_attributes = Room.stored_attributes[:settings]
    @setting_keys = settings.keys.map(&:to_sym)
    @same_settings = (@stored_attributes & @setting_keys == @stored_attributes)
    settings.blank? || !@same_settings
  end

  # If a setting is removed from store_accessor, remove it also from the settings in the db
  # returns true if a setting was removed
  def delete_settings
    @stored_attributes = Room.stored_attributes[:settings]
    @setting_keys = settings.keys.map(&:to_sym)
    @diff = @setting_keys - @stored_attributes
    @diff.each do |key|
      settings.delete(key.to_s)
    end
  end

  def initialize_setting_defaults
    # get the key value pair from the broker using the room_setting_defaults function
    room_settings = tenant_setting(tenant, 'room_setting_defaults')

    # Define default values
    defaults = {
      lockSettingsDisableCam: '0',
      lockSettingsDisableMic: '0',
      lockSettingsDisablePrivateChat: '0',
      lockSettingsDisablePublicChat: '0',
      lockSettingsDisableNote: '0',
      autoStartRecording: '0',
      allowStartStopRecording: '1',
      allModerators: '0',
      guestPolicy: '1',
      record: '1',
      defaultRecordingPublish: '0',
    }

    if room_settings.blank?
      # If room_settings is not present or null, assign defaults directly
      defaults.each do |key, value|
        send("#{key}=", value) unless send("#{key}_changed?")
      end
    else
      # Parse the values using the parse_defaults function
      parsed_defaults = parse_defaults(room_settings)

      # Iterate over default values and set them using send method
      defaults.each do |key, value|
        send("#{key}=", parsed_defaults.fetch(key, value)) unless send("#{key}_changed?")
      end
    end
  end

  def parse_defaults(defaults_str)
    defaults_str.gsub(/[{}]/, '').split(',').map do |pair|
      key, value = pair.split(':')
      [key.strip.to_sym, value.strip]
    end.to_h
  end

  def bool_to_binary(value)
    return '1' if value

    '0'
  end

  # Assign a random alphanumeric code to the room if it doesn't already have one
  # Assign the shared_code to equal to the room's code.
  def ensure_unique_code
    self.code = generate_unique_code
    self.shared_code = code if shared_code.blank? || !use_shared_code
  end

  def generate_unique_code
    loop do
      code = SecureRandom.alphanumeric(CODE_LENGTH)
      return code unless Room.exists?(code: code)
    end
  end

  def shared_code_presence
    errors.add(:shared_code, "The shared code can't be blank when 'Use Shared Code' is enabled") && return if shared_code.blank?

    return if Room.exists?(code: shared_code, tenant: tenant)

    errors.add(:shared_code, 'A room with this code could not be found')
  end
end
