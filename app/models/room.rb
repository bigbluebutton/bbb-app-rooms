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
  before_save :default_values

  store_accessor :settings, [:lockSettingsDisableCam, :lockSettingsDisableMic, :lockSettingsDisablePrivateChat, :lockSettingsDisablePublicChat, :lockSettingsDisableNote]
  store_accessor :settings, [:waitForModerator, :allModerators, :record, :autoStartRecording, :allowStartStopRecording]
  after_find :initialize_setting_defaults, if: :settings_blank?
  after_find :delete_settings

  attr_accessor :can_grade

  def default_values
    self.handler ||= Digest::SHA1.hexdigest(SecureRandom.uuid)
    self.moderator = random_password(8) if moderator.blank?
    self.viewer = random_password(8, moderator) if viewer.blank?
  end

  def broadcast_room_start
    ActionCable.server.broadcast("wait_channel:room_#{id}", action: 'started')
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
    self.lockSettingsDisableCam = '0'  unless lockSettingsDisableCam_changed?
    self.lockSettingsDisableMic = '0'  unless lockSettingsDisableMic_changed?
    self.lockSettingsDisablePrivateChat = '0' unless lockSettingsDisablePrivateChat_changed?
    self.lockSettingsDisablePublicChat = '0' unless lockSettingsDisablePublicChat_changed?
    self.lockSettingsDisableNote = '0' unless lockSettingsDisableNote_changed?
    self.autoStartRecording = '0'  unless autoStartRecording_changed?
    self.allowStartStopRecording = '1' unless allowStartStopRecording_changed?

    # these settings existed as their own column in the db
    # therefore we take the value in that column if it already exists
    # this is done to ensure previous values are not overwritten.
    self.waitForModerator = wait_moderator.nil? ? '0' : bool_to_binary(wait_moderator) unless waitForModerator_changed?
    self.allModerators = all_moderators.nil? ? '0' : bool_to_binary(all_moderators) unless waitForModerator_changed?
    self.record = record.nil? ? '1' : bool_to_binary(record) unless record_changed?
  end

  def bool_to_binary(value)
    return '1' if value

    '0'
  end
end
